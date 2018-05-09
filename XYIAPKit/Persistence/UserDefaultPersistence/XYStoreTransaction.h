//
//  XYStoreTransaction.h
//  Pods
//
//  Created by qichao.ma on 2018/4/19.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface XYStoreTransaction : NSObject<NSCoding>

@property(nonatomic, assign) BOOL consumed;
@property(nonatomic, copy) NSString *productIdentifier;
@property(nonatomic, copy) NSDate *transactionDate;
@property(nonatomic, copy) NSString *transactionIdentifier;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
@property(nonatomic, strong) NSData *transactionReceipt;
#endif

- (instancetype)initWithPaymentTransaction:(SKPaymentTransaction*)paymentTransaction;

@end
