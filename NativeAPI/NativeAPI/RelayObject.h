//
//  RelayObject.h
//  NativeAPI
//
//  Created by yin shen on 7/21/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ROArgs : NSObject

@property (nonatomic) char                  *type;
@property (nonatomic, retain) NSString      *name;
@property (nonatomic, retain) Class         argClass;

@end

@interface RelayObject : NSObject

/* api name example:share */
@property (nonatomic, readonly) NSString *apiName;
/* api prototype example:share(shareTitle,shareChannel)->(ret) */
@property (nonatomic, readonly) NSString *apiPrototype;
/* reflect by method name */
@property (nonatomic, assign, readonly) SEL cmd;
@property (nonatomic, readonly) Class handlerClazz;

@property (nonatomic, readonly) NSArray *argsTypeList;

@property (nonatomic, assign, readonly) BOOL hasCallback;


+ (instancetype)relayObject:(NSString *)expression;

@end
