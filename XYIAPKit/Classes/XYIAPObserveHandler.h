//
//  XYIapObserveHandler.h
//  GTMBase64
//
//  Created by Frenzy-Mac on 2017/10/13.
//

#import <Foundation/Foundation.h>
#import "XYIAPObserveProtocol.h"

@class SKPaymentTransaction;
@interface XYIAPObserveHandler : NSObject

+ (instancetype)shareInstance;

- (void)registerObserver:(id)observer;

- (void)unregisterObserver:(id)observer;

- (void)notifyWithIdentifier:(NSString *)identifier result:(BOOL)isValid;

@end
