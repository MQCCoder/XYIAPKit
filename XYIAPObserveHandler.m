//
//  XYIapObserveHandler.m
//  GTMBase64
//
//  Created by Frenzy-Mac on 2017/10/13.
//

#import "XYIAPObserveHandler.h"
#import "StoreKit/StoreKit.h"

@interface XYIAPObserveHandler () {
    NSHashTable         *_observers;
}

@end

@implementation XYIAPObserveHandler

+ (instancetype)shareInstance
{
    static XYIAPObserveHandler *shareInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[XYIAPObserveHandler alloc] init];
    });
    
    return shareInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _observers = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
    }
    return self;
}

#pragma mark - Observer

- (void)registerObserver:(id)observer {
    if (![_observers containsObject:observer]) {
        [_observers addObject:observer];
    }
}

- (void)unregisterObserver:(id)observer {
    [_observers removeObject:observer];
}

#pragma mark - Notify

- (void)notifyWithIdentifier:(NSString *)identifier result:(BOOL)isValid
{
    for (id observer in _observers) {
        if ([observer respondsToSelector:@selector(observeIAPWithIdentifier:result:)]) {
            [observer observeIAPWithIdentifier:identifier result:isValid];
        }
    }
}

@end
