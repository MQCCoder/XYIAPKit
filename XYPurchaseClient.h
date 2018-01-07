//
//  XYPurchaseClient.h
//  Pods
//
//  Created by qichao.ma on 2017/12/19.
//

#import <Foundation/Foundation.h>
#import "StoreKit/StoreKit.h"
#import "XYIAPObserveHandler.h"
#import "XYIAPObserveProtocol.h"

typedef enum : NSUInteger {
    /* 请求内购项 */
    XYIAPRequestResultNoPermission,   //用户不允许获取内购项
    XYIAPRequestResultSuccess,        //请求成功
    XYIAPRequestResultFailed          //请求失败
} XYIAPRequestResult;

typedef enum : NSUInteger {
    /* 购买结果 */
    XYIAPPurchaseResultFailed,                  //失败
    XYIAPPurchaseResultFailedCanceled,          //失败：用户取消
    XYIAPPurchaseResultFailedNoProduct,         //失败：没有查询到该商品
    XYIAPPurchaseResultFailedCreatePayment,     //失败：创建购买失败
    XYIAPPurchaseResultFailedNoPermission,      //失败：用户不允许
    
    XYIAPPurchaseResultSuccess,                 //成功
} XYIAPPurchaseResult;

typedef enum : NSUInteger {
    /* 购买结果 */
    XYIAPRestorePurchaseResultFailed,                   //失败：创建购买失败
    XYIAPRestorePurchaseResultFailedNoIdentifier,       //失败：没有查询到该商品
    
    XYIAPRestorePurchaseResultSuccess,                  //成功：单项成功
    XYIAPRestorePurchaseResultSuccessNoPurchased,       //成功：未发生过交易
    XYIAPRestorePurchaseResultSuccessAllCompleted,      //成功
} XYIAPRestorePurchaseResult;

typedef void(^XYIAPResponseBlock)(XYIAPRequestResult result);
typedef void(^XYIAPPurchaseBlock)(XYIAPPurchaseResult result);
typedef void(^XYIAPRestorePurchaseBlock)(XYIAPRestorePurchaseResult result);

@interface XYPurchaseClient : NSObject

@property (nonatomic ,assign) NSInteger purchaseRetryCount;//尝试多少次重新购买

+ (void)registerObserver:(id<XYIAPObserveProtocol>)observer;

/// optional, 对象销毁后会自动释放
+ (void)unregisterObserver:(id<XYIAPObserveProtocol>)observer;

/*
 *  向AppStore请求内购项，需要应用初始化时调用
 */
- (void)requestProductsWithProductIdentifiers:(NSArray *)productIdentifiers block:(XYIAPResponseBlock)block;

/*
 *  购买内购项
 */
- (void)purchase:(NSString *)iapProductId block:(XYIAPPurchaseBlock)block;

/*
 *  订阅
 */
- (void)subscribe:(NSString *)iapProductId sharedscretKey:(NSString *)sharedscretKey block:(XYIAPPurchaseBlock)block;

/*
 *  恢复内购项
 */
- (void)restorePurchases:(XYIAPRestorePurchaseBlock)block;

@end
