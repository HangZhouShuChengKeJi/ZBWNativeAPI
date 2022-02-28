//
//  RelayObject.m
//  NativeAPI
//
//  Created by yin shen on 7/21/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import "RelayObject.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation ROArgs

@end

@interface RelayObject ()
@property (nonatomic, retain) NSString *apiName;
@property (nonatomic, retain) NSString *apiPrototype;
@property (nonatomic, assign) SEL cmd;
@property (nonatomic) Class handlerClazz;

@property (nonatomic, retain) NSArray *argsTypeList;

@property (nonatomic, assign) BOOL hasCallback;

@end

@implementation RelayObject


+ (instancetype)relayObject:(NSString *)expression {
    ///share(shareTitle,shareUrl)->(ret)~ShareController
    NSString *eachApi = [expression stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (eachApi.length == 0) {
        return nil;
    }
    
    NSLog(expression);
    NSScanner *scanner = [NSScanner scannerWithString:eachApi];
    NSString *apiName = NULL;
    // apiName
    if ([scanner scanUpToString:@"(" intoString:&apiName] && [scanner isAtEnd]) {
        return nil;
    }
    apiName = [apiName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 参数
    NSString *params = NULL;
    if ([apiName isEqualToString:@"setProblemListState"]) {
        
    }
    scanner.scanLocation += @"(".length;
    if ([scanner scanUpToString:@")->(" intoString:&params] && [scanner isAtEnd]) {
        return nil;
    }
    scanner.scanLocation += @")->(".length;
    params = [params stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray *paramsProperty = [NSMutableArray arrayWithCapacity:4];
    if (params.length > 0) {
        // 解析参数
        NSArray *paramsList = [params componentsSeparatedByString:@","];
        [paramsList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *paramStr = obj;
            paramStr = [paramStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSArray *list = [paramStr componentsSeparatedByString:@" "];
            
            ROArgs *arg = [[ROArgs alloc] init];
            for (NSInteger i = list.count - 1; i >= 0; i--) {
                NSString *value = list[i];
                if (i == list.count - 1) {
                    arg.name = value;
                    continue;
                }
                if (value.length == 0) {
                    continue;
                }
                arg.argClass = NSClassFromString(value);
            }
            [paramsProperty addObject:arg];
        }];
    }
    
    // 返回参数
    NSString *returnParams = NULL;
    if ([scanner scanUpToString:@")~" intoString:&returnParams] && [scanner isAtEnd]) {
        return nil;
    }
    scanner.scanLocation += @")~".length;
    // 处理器
    NSString *handler = [[eachApi substringFromIndex:scanner.scanLocation] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (handler.length == 0) {
        return nil;
    }
    
    Class handlerClass = NSClassFromString(handler);
    if (!handlerClass) {
        return nil;
    }
    
    // SEL
    NSMutableString *selName = [[NSMutableString alloc]
                                initWithFormat:@"NativE_%@_context:",apiName];
    
    
    for (int i = 0; i < paramsProperty.count; ++i) {
        ROArgs *arg = paramsProperty[i];
        [selName appendFormat:@"%@:",arg.name];
    }
    
    // 无回调
    NSString *selectWithoutCallback = selName.copy;
    // 有回调
    NSString *selectWithCallback = [NSString stringWithFormat:@"%@%@", selectWithoutCallback, @"callback:"];
    
    SEL sel = NSSelectorFromString(selectWithCallback);
    
    BOOL hasCallback = YES;
    Method method = class_getInstanceMethod(handlerClass, sel);
    if (method == NULL) {
        sel = NSSelectorFromString(selectWithoutCallback);
        method = class_getInstanceMethod(handlerClass, sel);
        hasCallback = NO;
    }
    if (method == NULL) {
        return nil;
    }
    
    RelayObject *rO = [[RelayObject alloc] init];
    rO.handlerClazz = handlerClass;
    rO.cmd = sel;
    rO.apiName = apiName;
    rO.hasCallback = hasCallback;
    rO.argsTypeList = paramsProperty;
    
    // 参数类型解析
    for (int i = 0; i < paramsProperty.count; ++i) {
        ROArgs *arg = paramsProperty[i];
        arg.type = method_copyArgumentType(method, i + 3);
    }
    
    return rO;
}



//- (NSArray *)parseArgs:(NSDictionary *)data {
//    for (int i = 0 ; i < self.args.count; i++) {
//        ROArgs *arg = self.args[i];
//        NSString *name = arg.name;
//        id value = data[name];
//        
//        
//    }
//}

@end
