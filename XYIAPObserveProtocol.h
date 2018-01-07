//
//  XYIapObserveProtocol.h
//  Pods
//
//  Created by Frenzy-Mac on 2017/10/13.
//

#import <Foundation/Foundation.h>
#import "XYIAPConfigItem.h"
#import "XYIAPProductInfo.h"
#import "StoreKit/StoreKit.h"

#ifndef XYIAPObserveProtocol_h
#define XYIAPObserveProtocol_h

typedef enum : NSUInteger {
    
    /* 购买内购项 */
    XYIAPStatePurchaseFailedNoIdentifiers,      //失败：没有获取到内购项列表
    XYIAPStatePurchaseFailedNoProduct,          //失败：没有获取的内购项信息
    XYIAPStatePurchaseFailedCreatePayment,      //失败：创建购买失败
    
    XYIAPStatePurchaseStart,                    //开始请求AppStore服务器
    XYIAPStatePurchaseSuccess,                  //成功
    XYIAPStatePurchaseFailed,                   //失败：AppStore服务器返回失败
    XYIAPStatePurchaseCanceled,                 //用户取消
    
    /* 恢复内购项 */
    XYIAPStateRestoreFailedNoIdentifiers,       //失败：没有获取到内购项列表
    XYIAPStateRestoreStart,                     //开始
    XYIAPStateRestoreSuccess,                   //成功(单项)
    XYIAPStateRestoreFailed,                    //失败：AppStore服务器返回失败
    XYIAPStateRestoreNoPurchased,               //成功：未发生过交易
    XYIAPStateRestoreAllCompleted,              //成功
    XYIAPStateRestoreAllCompletedAndValid,      //成功: Check后是可用的
    XYIAPStateRestoreAllCompletedAndInvalid,    //成功: Check后是不可用的
    
} XYIAPState;

@protocol XYIAPObserveProtocol <NSObject>

@required

- (void)observeIAPWithIdentifier:(NSString *)identifier result:(BOOL)isValid;

@optional


@end

#endif /* XYIapObserveProtocol_h */
