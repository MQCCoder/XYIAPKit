//
//  XYIAPManager.h
//  Pods
//
//  Created by mqc on 2018/1/8.
//

#import <Foundation/Foundation.h>
#import "XYIAPObserveProtocol.h"
#import "StoreKit/StoreKit.h"

typedef enum : NSUInteger {
    /* 请求内购项 */
    XYIAPRequestResultNoPermission,   //用户不允许获取内购项
    XYIAPRequestResultSuccess,        //请求成功
    XYIAPRequestResultFailed          //请求失败
} XYIAPRequestResult;

typedef void(^XYIAPResponseBlock)(XYIAPRequestResult result);

@class SKPaymentTransaction;
@interface XYIAPManager : NSObject

+ (instancetype)shareInstance;

- (void)registerObserver:(id)observer;

- (void)unregisterObserver:(id)observer;

- (void)notifyWithIdentifier:(NSString *)identifier result:(BOOL)isValid;

- (void)requestProductsWithProductIdentifiers:(NSArray *)productIdentifiers
                                        block:(XYIAPResponseBlock)block;

- (BOOL)isValidProduct:(NSString *)identifier;

- (SKProduct *)skProductWithIdentifier:(NSString *)identifier;

@end
