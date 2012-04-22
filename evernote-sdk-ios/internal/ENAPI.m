//
//  ENAPI.m
//  evernote-sdk-ios
//
//  Created by Matthew McGlincy on 4/21/12.
//  Copyright (c) 2012 n/a. All rights reserved.
//

#import "ENAPI.h"
#import "EDAM.h"

@interface ENAPI()

@end

@implementation ENAPI

@synthesize session = _session;
@synthesize error = _error;
@dynamic noteStore;
@dynamic userStore;

- (void)dealloc
{
    [_session release];
    [super dealloc];
}

- (id)initWithSession:(EvernoteSession *)session
{
    self = [super init];
    if (self) {
        self.session = session;
    }
    return self;
}

- (EDAMNoteStoreClient *)noteStore
{
    return [self.session noteStore];
}

- (EDAMUserStoreClient *)userStore
{
    return [self.session userStore];    
}

- (NSError *)errorFromNSException:(NSException *)exception
{
    if (exception) {
        int errorCode = EDAMErrorCode_UNKNOWN;
        if ([exception respondsToSelector:@selector(errorCode)]) {
            // Evernote Thrift exception classes have an errorCode property
            errorCode = [(id)exception errorCode];
        }
        return [NSError errorWithDomain:kEvernoteSDKErrorDomain code:errorCode userInfo:exception.userInfo];
    }
    return nil;
}

- (void)invokeVoidBlock:(void(^)())block
{
    self.error = nil;
    @try {
        block();
    }
    @catch (NSException *exception) {
        self.error = [self errorFromNSException:exception];
    }
}

- (BOOL)invokeBoolBlock:(BOOL(^)())block
{
    self.error = nil;
    BOOL retVal = NO;
    @try {
        retVal = block();
    }
    @catch (NSException *exception) {
        self.error = [self errorFromNSException:exception];
    }
    return retVal;
}

- (int32_t)invokeInt32Block:(int32_t(^)())block
{
    self.error = nil;
    int32_t retVal = 0;
    @try {
        retVal = block();
    }
    @catch (NSException *exception) {
        self.error = [self errorFromNSException:exception];
    }
    return retVal;
}

- (NSObject *)invokeObjBlock:(NSObject *(^)())block
{
    self.error = nil;
    NSObject *retVal = nil;
    @try {
        retVal = block();
    }
    @catch (NSException *exception) {
        self.error = [self errorFromNSException:exception];
    }
    return retVal;   
}

- (void)invokeAsyncBlock:(void(^)())block
                 failure:(void(^)(NSError *error))failure
{
    @try {
        block();
    }
    @catch (NSException *exception) {
        NSError *error = [self errorFromNSException:exception];
        failure(error);
    }
}

/*
 doesn't work generically because of type-checking
- (void)invokeAsyncObjBlock:(NSObject *(^)())block
                    success:(void(^)(NSObject *obj))success
                    failure:(void(^)(NSError *error))failure
{
    // run the block on a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSObject *retVal = nil;
        @try {
            retVal = block();
            // callback on the main thread
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               success(retVal);
                           });
        }
        @catch (NSException *exception) {
            NSError *error = [self errorFromNSException:exception];
            // callback on the main thread
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               failure(error);
                           });
        }
    });
}
*/

- (void)invokeAsyncNSArrayBlock:(NSArray *(^)())block
                        success:(void(^)(NSArray *val))success
                        failure:(void(^)(NSError *error))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSArray *retVal = nil;
        @try {
            retVal = block();
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               success(retVal);
                           });
        }
        @catch (NSException *exception) {
            NSError *error = [self errorFromNSException:exception];
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               failure(error);
                           });
        }
    });
}

- (void)invokeAsyncInt32Block:(int32_t(^)())block
                      success:(void(^)(int32_t val))success
                      failure:(void(^)(NSError *error))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        int32_t retVal = -1;
        @try {
            retVal = block();
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               success(retVal);
                           });
        }
        @catch (NSException *exception) {
            NSError *error = [self errorFromNSException:exception];
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               failure(error);
                           });
        }
    });
}


@end
