//
//  ViewController.m
//  NativeAPIDemo
//
//  Created by 朱博文 on 16/7/5.
//  Copyright © 2016年 朱博文. All rights reserved.
//

#import "ViewController.h"
#import "NativeRelay.h"

@interface ViewController ()<UIWebViewDelegate>

@property (nonatomic) UIWebView     *webView;
@property (nonatomic) NativeRelay   *nativeRelay;

@end

@implementation ViewController

+ (NSString *)jsonRepresentation:(id)obj {
    NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    if (!data) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.webView];
    
    __weak typeof(self) weakself = self;
    [TF8_NR(@"zhubowen") addContext:self callbackToH5:^(NSDictionary *userInfo) {
        NSLog(@"%@", userInfo);
        NSString *jsonStr = [ViewController jsonRepresentation:userInfo];
        NSString* javascriptCommand = [NSString stringWithFormat:@"window.LeixunJSBridge.callback(%@,%@);",userInfo[@"cbId"], jsonStr];
        [weakself.webView stringByEvaluatingJavaScriptFromString:javascriptCommand];
    } pullMQEvent:^(id content) {
        NSString* javascriptCommand = [NSString stringWithFormat:@"window.LeixunJSBridge.pullMQ();"];
        [weakself.webView stringByEvaluatingJavaScriptFromString:javascriptCommand];
    }];
    
    NSLog(@"apilist: %ld %@", TF8_NR(@"zhubowen").apiList.count, TF8_NR(@"zhubowen").apiList);
    
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [self.webView loadHTMLString:appHtml baseURL:baseURL];
}

// js-event://
- (UIWebView *)webView
{
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.scalesPageToFit = YES;
        _webView.delegate = self;
    }
    return _webView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = request.URL;
    NSString *urlStr = url.absoluteString;
    NSLog(@"url: %@", urlStr);
    [TF8_NR(@"zhubowen") dispatch:url context:self];
    return YES;
}


@end
