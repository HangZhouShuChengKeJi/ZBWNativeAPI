//
//  NativeAbility.m
//  NativeAPIDemo
//
//  Created by 朱博文 on 16/7/22.
//  Copyright © 2016年 朱博文. All rights reserved.
//

#import "NativeAbility.h"
#import <UIKit/UIKit.h>
#import "UIAlertView+Blocks.h"


@interface NativeAbility ()<UIAlertViewDelegate>

@end

@implementation NativeAbility

- (void)NativE_pop_context:(id)context
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)NativE_alert_context:(id)context title:(NSString *)title message:(NSString *)msg cancelButtonTitle:(NSString *)cancelTitle confirmButtonTitle:(NSString *)confirmTitle callback:(void(^)(NSDictionary *))callback
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:cancelTitle otherButtonTitles:confirmTitle, nil];
    [alertView showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        callback(@{@"index":@(buttonIndex)});
    }];
#pragma clang diagnostic pop
}


@end
