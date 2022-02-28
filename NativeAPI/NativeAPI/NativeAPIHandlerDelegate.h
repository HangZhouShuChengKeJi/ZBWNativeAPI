//
//  NativeAPIDelegate.h
//  AFNetworking-iOS10.3
//
//  Created by 朱博文 on 2018/11/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TF8_NR_NativeToH5Callback)(NSDictionary *userInfo);
typedef void (^TF8_NR_PullMQEventBlock)(id content);

@protocol NativeAPIHandlerDelegate <NSObject>

@required
- (BOOL)nativeAPIHandler:(nonnull NSString *)type params:(nullable NSDictionary *)params callback:(TF8_NR_NativeToH5Callback)callback;

@end

NS_ASSUME_NONNULL_END
