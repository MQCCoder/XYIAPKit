//
//  XYReceiptHandler.h
//  Pods
//
//  Created by qichao.ma on 2017/12/22.
//

#import <Foundation/Foundation.h>

typedef void (^IAPCheckReceiptCompleteBlock)(BOOL isValid);

@interface XYReceiptHandler : NSObject

- (void)checkSubscribeRecieptWithIdentifier:(NSString *)identifier
                             sharedscretKey:(NSString *)sharedscretKey
                                  isSandbox:(BOOL)isSandbox
                                      block:(IAPCheckReceiptCompleteBlock)block;

- (void)checkPurchaseRecieptWithIdentifier:(NSString *)identifier
                                 isSandbox:(BOOL)isSandbox
                                     block:(IAPCheckReceiptCompleteBlock)block;

@end
