//
//  NativeAPITests.m
//  NativeAPITests
//
//  Created by yin shen on 7/21/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NativeRelay.h"

@interface NativeAPITests : XCTestCase

@end

@implementation NativeAPITests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAPIList{
    NSString *path = @"/Users/yinshen/Desktop/NativeAPI/NativeAPITests/NativeAPIList.txt";
    NativeRelay *relay = [[NativeRelay alloc] init];
    [relay loadAPIList];
}

- (void)testUriParser{
    NSURL *url = [NSURL URLWithString:@"native-server://api/share"];
                                          
    NativeRelay *relay = [[NativeRelay alloc] init];
    [relay dispatch:url];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
