//
//  NativeRelay.h
//  NativeAPI
//
//  Created by yin shen on 7/21/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NativeAPIHandlerDelegate.h"

// 获取identity对应的【NativeRelay】对象
#define TF8_NR(identify)    ([NativeRelay instanceWithIdentify:identify])


/*!
 *Native API Prototype
 *na_apiname_context:arg1:arg2:arg3:...cbId:
 */

@class RelayObject;

/**
 *  【 NativeRelay 】
 *   解析本地的apilist、接收H5传递给来的消息、解析url、调用协议方法、回调上层(上层再调js，回调到H5);
 *   
     1) 一个NativeRelay对应一个apilist（伪协议）, 在注册的时候传入。
     2）NativeRelay 与 UIWebView/UIWebwiewController是 “一对多” 的关系，因为多个H5页面可以使用相同的伪协议。每个UIWebView/UIWebwiewController，都是NativeRelay的一个context，因此NativeRelay与context也是“一对多”。
 *
 */
@interface NativeRelay : NSObject

///* binding context */
//@property (nonatomic, readonly) id context;
/* server name default is "native-server" */
@property (nonatomic, retain) NSArray *schemeList;
@property (nonatomic, retain) NSString  *pullMQScheme;
@property (nonatomic, readonly) NSArray *apiList;           // 可以被H5调用的Api list

#if DEBUG
@property (nonatomic, readonly) NSString *testUrl;
#endif

/**
 *  注册并创建一个NativeRely
 *
 *  @param identifyStr 唯一标示
 *  @param path        apilist文件的路径
 *
 *  @return 实例对象
 */
+ (instancetype)registerWithIdentify:(NSString *)identifyStr
                         APIlistPath:(NSString *)path;
+ (void)unregisterWithIdentify:(NSString *)identifyStr;

/**
 *  获取已经注册过的实例对象
 *
 *  @param identifyStr 唯一标示
 *
 *  @return 实例对象
 */
+ (instancetype)instanceWithIdentify:(NSString *)identifyStr;

/**
 *  添加context 并 设置native回调h5的block
 *
 *  @param context  context，一般为ViewController或者Webview。 弱引用。
 *  @param callback 回到到H5的入口
 */
- (void)addContext:(nonnull id<NativeAPIHandlerDelegate>)context
      callbackToH5:(nonnull TF8_NR_NativeToH5Callback)callback;

/**
 *  添加context 并 设置native回调h5的block
 *
 *  @param context  context，一般为ViewController或者Webview。 弱引用。
 *  @param callback 回到到H5的入口
 *  @param pullMQEvent 触发拉取mq消息队列
 */
- (void)addContext:(nonnull id<NativeAPIHandlerDelegate>)context
      callbackToH5:(nonnull TF8_NR_NativeToH5Callback)callback
       pullMQEvent:(TF8_NR_PullMQEventBlock)pullMQEvent;

/**
 *  解析url,并执行
 *
 *  @param uri     url
 *  @param context context，必须传。与 addContext:callbackToH5: 的context一致
 */
- (void)dispatch:(nonnull NSURL *)uri
         context:(nonnull id)context;

- (void)dispatchWithData:(nonnull NSDictionary *)data
                 context:(nonnull id)context;
@end



