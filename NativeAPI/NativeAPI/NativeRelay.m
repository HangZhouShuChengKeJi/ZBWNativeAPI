//
//  NativeRelay.m
//  NativeAPI
//
//  Created by yin shen on 7/21/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import "NativeRelay.h"
#import "RelayObject.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <ZBWJson.h>


#define NR_WeakSelf     __weak typeof(self) weakSelf = self;


static inline int zbw_strprefix(const char *str, const char *prefix){
    int step = 0;
    size_t str_len = strlen(str);
    size_t prefix_len = strlen(prefix);
    
    if (prefix_len > str_len) return -1;
    
    while (step<prefix_len) {
        if (str[step] == prefix[step]) step++;
        else return -1;
    }
    
    return 0;
}

// NativeRelay的字典  key：identify， value：NativeRelay
NSMutableDictionary* NA_nativeRelayMap()
{
    static NSMutableDictionary *dic = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dic = [NSMutableDictionary dictionaryWithCapacity:2];
    });
    return dic;
}

// 保护NativeRelay字典的Lock
NSLock *NA_lock()
{
    static NSLock *lock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [[NSLock alloc] init];
    });
    return lock;
}

/**
 *  NativeRelay的context需要保存，且有多个context，如果直接使用NSArray保存，强引用，导致cycle retain。因此使用NativeRelayContext，弱引用保存context，强引用的是NativeRelayContext。
 */
@interface NativeRelayContext : NSObject

@property (weak,nonatomic) id<NativeAPIHandlerDelegate> context;
@property (nonatomic, copy) TF8_NR_NativeToH5Callback callback;
@property (nonatomic, copy) TF8_NR_PullMQEventBlock   pullMQEventBlock;

@end

@implementation NativeRelayContext
@end

/***********************************************************************************************
 **********************************************************************************************/

static NSString *kNativeRelayDefaultServerName = @"native-server";

@interface NativeRelay ()

@property (nonatomic) NSMutableDictionary   *apiMap;            // api 字典 key: apiName, value:RelayObject
@property (nonatomic) NSMutableDictionary   *contextMap;        // context字典 key: context地址串，value:NativeRelayContext
@property (nonatomic) dispatch_queue_t      queue;              // 同步队列

@property (nonatomic, copy) NSString        *identify;          // 唯一标示
@property (nonatomic) NSArray               *apiList;           // apilist

@end

@implementation NativeRelay

#pragma mark- Public static 方法

+ (instancetype)registerWithIdentify:(NSString *)identifyStr APIlistPath:(NSString *)path
{
    if (!identifyStr) {
        return nil;
    }
    NSLock *lock = NA_lock();
    
    [lock lock];
    NSMutableDictionary *map = NA_nativeRelayMap();
    id nr = map[identifyStr];
    NSAssert(!nr, ([NSString stringWithFormat:@"%@ 已经注册过，不能重复注册！！",identifyStr]));
    
    nr = [[NativeRelay alloc] init];
    map[identifyStr] = nr;
    [lock unlock];
    
    [nr loadAPIListWithPath:path];
    return nr;
}

+ (void)unregisterWithIdentify:(NSString *)identifyStr
{
    if (!identifyStr) {
        return;
    }
    NSLock *lock = NA_lock();
    
    [lock lock];
    NSMutableDictionary *map = NA_nativeRelayMap();
    [map removeObjectForKey:identifyStr];
    [lock unlock];
}

+ (instancetype)instanceWithIdentify:(NSString *)identifyStr
{
    if (!identifyStr) {
        return nil;
    }
    NSLock *lock = NA_lock();
    
    [lock lock];
    NSMutableDictionary *map = NA_nativeRelayMap();
    id nr = map[identifyStr];
    [lock unlock];
    
    return nr;
}

#pragma mark- Public 方法
- (void)addContext:(id<NativeAPIHandlerDelegate>)context callbackToH5:(void (^)(NSDictionary *))callback
{
    NSAssert(context, @"NativeRelay 添加context不能为nil");
    NR_WeakSelf
    dispatch_async(self.queue, ^{
        if (!context) {
            return ;
        }
        NSString *key = [NSString stringWithFormat:@"%p", context];
        NativeRelayContext *c = weakSelf.contextMap[key];
        if (!c) {
            c = [[NativeRelayContext alloc] init];
            c.context = context;
            weakSelf.contextMap[key] = c;
        }
        c.callback = callback;
    });
}

- (void)addContext:(id<NativeAPIHandlerDelegate>)context
      callbackToH5:(TF8_NR_NativeToH5Callback)callback
       pullMQEvent:(TF8_NR_PullMQEventBlock)pullMQEvent {
    NSAssert(context, @"NativeRelay 添加context不能为nil");
    NR_WeakSelf
    dispatch_async(self.queue, ^{
        if (!context) {
            return ;
        }
        NSString *key = [NSString stringWithFormat:@"%p", context];
        NativeRelayContext *c = weakSelf.contextMap[key];
        if (!c) {
            c = [[NativeRelayContext alloc] init];
            c.context = context;
            weakSelf.contextMap[key] = c;
        }
        c.callback = callback;
        c.pullMQEventBlock = pullMQEvent;
    });
}

#pragma mark- Private 方法

- (void)clearInvalidContext
{
    NR_WeakSelf
    dispatch_async(self.queue, ^{
        [weakSelf.contextMap.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NativeRelayContext *c = weakSelf.contextMap[obj];
            if (!c.context) {
                [weakSelf.contextMap removeObjectForKey:obj];
            }
        }];
    });
}

- (id)init{
    if (self = [super init]) {
        self.schemeList = @[kNativeRelayDefaultServerName];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppicationResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadAPIListWithPath:(NSString *)path
{
    if (!path) {
        path = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/apimap"];
    }
    NR_WeakSelf
    dispatch_async(self.queue, ^{
        if (!weakSelf) {
            return ;
        }
        if (weakSelf.apiMap.count > 0) {
            return;
        }
        
        weakSelf.apiMap = [NSMutableDictionary dictionaryWithCapacity:5];
        
        NSString *fileStr = [[NSString alloc] initWithContentsOfFile:path
                                                            encoding:NSUTF8StringEncoding
                                                               error:nil];
        if (fileStr.length) {
            NSArray *apiSet = [fileStr componentsSeparatedByString:@"\n"];
            
            for (NSString *eachApiItem in apiSet) {
                RelayObject *rO = [RelayObject relayObject:eachApiItem];
                if (!rO) {
                    continue;
                }
                [weakSelf.apiMap setValue:rO forKey:rO.apiName];
            }
        }
    });
}

- (NSDictionary *)dataOfUrl:(NSURL *)uri {
    if (!uri) {
        return nil;
    }
    NSString *scheme = [uri scheme];
    // 校验 scheme
    if (scheme.length == 0 || ![self.schemeList containsObject:scheme]) {
        return nil;
    }
    // 校验host
    if (![[uri host] isEqualToString:@"api"]) {
        return nil;
    }
    
    NSString *apiName = [[uri path] substringFromIndex:1]; //ignore '/'in '/path'
    
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:3];
    data[@"func"] = apiName;
    
    NSArray *params = [[uri query] componentsSeparatedByString:@"&"];
    for (NSString *str in params) {
        
        NSRange range = [str rangeOfString:@"="];
        if (str != nil && range.location != NSNotFound) {
            NSString *key = [str substringToIndex:range.location];
            NSString *value = (str.length > (range.location + range.length) ? [str substringFromIndex:(range.location + range.length)] : @"");
            
            value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            if ([@"d" isEqualToString:key]) {
                NSDictionary *d = [self.class jsonValue:value];
                if (d) {
                    data[@"d"] = d;
                }
            }
            else if ([@"cb" isEqualToString:key]) {
                data[@"cb"] = value;
            }
        }
    }
    return data;
}


- (void)dispatchWithData:(NSDictionary *)data context:(id)context {
    if (!context || ![data isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NR_WeakSelf
    __weak typeof(context) weakContext = context;
    dispatch_async(self.queue, ^{
        if (!weakContext) {
            return ;
        }
        NSString *apiName = data[@"func"];
        RelayObject *rO = weakSelf.apiMap[apiName];
        
        [weakSelf invokeWithRelayObject:rO data:data context:weakContext];
    });
}

- (void)dispatch:(nonnull NSURL *)uri context:(nonnull id)context{
    if (!context) {
        return;
    }
    
    NSString *scheme = [uri scheme];
    if (scheme.length == 0 || ![self.schemeList containsObject:scheme]) {
        return;
    }
    
    NR_WeakSelf
    NSString *key = [NSString stringWithFormat:@"%p", context];
    
    // 如果scheme是触发事件，回调拉取mq
    if (self.pullMQScheme.length > 0 && [scheme isEqualToString:self.pullMQScheme]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NativeRelayContext *c = weakSelf.contextMap[key];
            c.pullMQEventBlock ? c.pullMQEventBlock(c.context) : nil;
        });
        return;
    }
    
    
    __weak typeof(context) weakContext = context;
    dispatch_async(self.queue, ^{
        if (!weakContext) {
            return;
        }
        NSDictionary *data = [weakSelf dataOfUrl:uri];
        if (!data || ![data isKindOfClass:[NSDictionary class]]) {
            return;
        }
        
        NSString *apiName = data[@"func"];
        RelayObject *rO = weakSelf.apiMap[apiName];
        
        [weakSelf invokeWithRelayObject:rO data:data context:weakContext];
    });
}

- (void)invokeWithRelayObject:(RelayObject *)rO data:(NSDictionary *)data context:(nonnull id)context{
    if (!context) {
        return;
    }
    
    NR_WeakSelf
    NSString *key = [NSString stringWithFormat:@"%p", context];
    NativeRelayContext *c = self.contextMap[key];
    
    NSString *cbId = data[@"cb"];
    // api 不存在，直接回调错误。
    if (!rO) {
        if (cbId) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:2];
                dic[@"errorCode"] = @"-1";
                dic[@"cbId"] = cbId;
                c.callback ? c.callback(dic) : nil;
            });
        }
        return;
    }
    
    id sender = [[rO.handlerClazz alloc] init];
    SEL cmd = rO.cmd;
    NSMethodSignature *signature = [rO.handlerClazz instanceMethodSignatureForSelector:cmd];
    NSInvocation *invocation  = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:sender];
    [invocation setSelector:cmd];
    
    [invocation setArgument:&sender atIndex:0];
    [invocation setArgument:&cmd atIndex:1];
    [invocation setArgument:&context atIndex:2];
    
    NSMutableArray *retainArray = [NSMutableArray arrayWithCapacity:10];
    [retainArray addObject:sender];
    
    NSInteger argsCount = rO.argsTypeList.count;
    for (int i = 0 ; i < argsCount; i++) {
        ROArgs *arg = rO.argsTypeList[i];
        NSString *name = arg.name;
        NSDictionary *bizData = data[@"d"];
        id value = bizData[name];
        
        int index = i + 3;
        
        // 传参不存在
        if (!value) {
            [invocation setArgument:&value atIndex:index];
            continue;
        }
        
        // 指定了参数类型
        if (arg.argClass) {
            // 字符串接收
            if (arg.argClass == NSString.class) {
                //
                if ([value isKindOfClass:[NSString class]]) {
                } else if ([value isKindOfClass:[NSDictionary class]]
                           || [value isKindOfClass:[NSArray class]]) {
                    value = [value zbw_jsonString];
                } else {
                    value = [value description];
                }
            }
            // NSNumber接收
            else if (arg.argClass == NSNumber.class) {
                if (![value isKindOfClass:[NSNumber class]]) {
                    value = NULL;
                }
            }
            // 数组接收 (暂不支持)
            else if ([arg.argClass isSubclassOfClass:[NSArray class]]) {
                if (![value isKindOfClass:[NSArray class]]) {
                    value = NULL;
                }
            }
            // 字典接收
            else if ([arg.argClass isSubclassOfClass:[NSDictionary class]]) {
                if (![value isKindOfClass:[NSDictionary class]]) {
                    value = NULL;
                }
            }
            // 自定义类接收
            else {
                if ([value isKindOfClass:[NSDictionary class]]) {
                    value = [[arg.argClass alloc] zbw_initWithJsonDic:value];
                } else if ([value isKindOfClass:[NSString class]]){
                    NSDictionary *dic = [value zbw_jsonObject];
                    if ([dic isKindOfClass:[NSDictionary class]]) {
                        value = [[arg.argClass alloc] zbw_initWithJsonDic:dic];
                    } else {
                        value = NULL;
                    }
                } else {
                    value = NULL;
                }
            }
            [invocation setArgument:&value atIndex:index];
            if (value) {
                [retainArray addObject:value];
            }
        } else {
            // 没有指定参数类型， 通过runtime获取大概的类型
            char signType = arg.type[0];
            
            if (signType == _C_ID) {
                [invocation setArgument:&value atIndex:index];
                
                if (value) {
                    [retainArray addObject:value];
                }
            } else {
                if ([value isKindOfClass:[NSNumber class]]) {
#define __zbw_case_nsnumber(__typeChar__,__type__,__convertType___)\
case(__typeChar__):{\
__type__ v = [value __convertType___];\
[invocation setArgument:&v atIndex:index++];\
}\
break;
                    
                    switch (signType) {
                            __zbw_case_nsnumber(_C_SHT, short, shortValue)
                            __zbw_case_nsnumber(_C_USHT, unsigned short, unsignedShortValue)
                            __zbw_case_nsnumber(_C_INT, int, intValue)
                            __zbw_case_nsnumber(_C_UINT,unsigned int, unsignedIntValue)
                            __zbw_case_nsnumber(_C_LNG, long, longValue)
                            __zbw_case_nsnumber(_C_ULNG,unsigned long, unsignedLongValue)
                            __zbw_case_nsnumber(_C_FLT, float, floatValue)
                            __zbw_case_nsnumber(_C_DBL, double, doubleValue)
                            __zbw_case_nsnumber(_C_ULNG_LNG, unsigned long long, unsignedLongLongValue)
                            __zbw_case_nsnumber(_C_LNG_LNG, long long, longLongValue)
                            __zbw_case_nsnumber(_C_BOOL, BOOL, boolValue)
                        default:
                            break;
                    }
                    
                }
                else if ([value isKindOfClass:[NSValue class]]){
                    if (zbw_strprefix(arg.type,"{CGRect") == 0) {
                        CGRect r = [value CGRectValue];
                        [invocation setArgument:&r atIndex:index];
                    }
                    else if (zbw_strprefix(arg.type,"{CGPoint") == 0) {
                        CGPoint p = [value CGPointValue];
                        [invocation setArgument:&p atIndex:index];
                    }
                    else if (zbw_strprefix(arg.type,"{CGSize") == 0) {
                        CGSize  s = [value CGSizeValue];
                        [invocation setArgument:&s atIndex:index];
                    }
                }
            }
        }
    }
    
    TF8_NR_NativeToH5Callback cb;
    if (rO.hasCallback) {
        // 添加回调block
        cb = ^(NSDictionary *userInfo){
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:userInfo];
            dic[@"cbId"] = cbId ?: @(99999);
            if ([NSThread isMainThread]) {
                c.callback ? c.callback(dic) : nil;
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    c.callback ? c.callback(dic) : nil;
                });
            }
        };
        [invocation setArgument:&cb atIndex:3 + argsCount];
    };
    
    [invocation retainArguments];
    if (cb) {
        [retainArray addObject:cb];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [invocation invoke];
        retainArray ?nil:nil;
    });
}



- (NSString *)testUrl{
    //    return @"http://42.121.77.5/";
    
    return @"http://0.0.0.0:8080/";
}


+ (id)jsonValue:(NSString *)str
{
    if ([str isKindOfClass:[NSDictionary class]]) {
        return str;
    }
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}


#pragma mark- Getter 方法
- (dispatch_queue_t)queue
{
    if (!_queue) {
        _queue = dispatch_queue_create("com.NativeRelay.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}

- (NSMutableDictionary *)contextMap
{
    @synchronized (self) {
        if (!_contextMap) {
            _contextMap = [NSMutableDictionary dictionaryWithCapacity:3];
        }
    }
    return _contextMap;
}

- (NSArray *)apiList
{
    if (_apiList) {
        return _apiList;
    }
    NR_WeakSelf
    dispatch_sync(self.queue, ^{
        weakSelf.apiList = weakSelf.apiMap.allKeys;
    });
    return _apiList;
}

#pragma mark- Event 事件

- (void)onAppicationResignActive:(NSNotification *)notify
{
    NR_WeakSelf
    dispatch_async(self.queue, ^{
        [weakSelf clearInvalidContext];
    });
}

@end
