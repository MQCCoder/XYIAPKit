//
//  NSNotification+XYStore.h
//  Pods
//
//  Created by qichao.ma on 2018/4/20.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

extern NSString *const XYStoreNotificationInvalidProductIdentifiers;
extern NSString *const XYStoreNotificationDownloadProgress;
extern NSString *const XYStoreNotificationProductIdentifier;
extern NSString *const XYStoreNotificationProducts;
extern NSString *const XYStoreNotificationStoreDownload;
extern NSString *const XYStoreNotificationStoreError;
extern NSString *const XYStoreNotificationStoreReceipt;
extern NSString *const XYStoreNotificationTransaction;
extern NSString *const XYStoreNotificationTransactions;

/**
 Category on NSNotification to recover store data from userInfo without requiring to know the keys.
 */
@interface NSNotification (XYStore)

@property (nonatomic, readonly) float xy_downloadProgress;

/** Array of product identifiers that were not recognized by the App Store. Used in @c storeProductsRequestFinished:.
 */
@property (nonatomic, readonly) NSArray *xy_invalidProductIdentifiers;

/** Used in @c storeDownload*:, @c storePaymentTransactionFinished: and @c storePaymentTransactionFailed:.
 */
@property (nonatomic, readonly) NSString *xy_productIdentifier;

/** Array of SKProducts, one product for each valid product identifier provided in the corresponding request. Used in @c storeProductsRequestFinished:.
 */
@property (nonatomic, readonly) NSArray *xy_products;

/** Used in @c storeDownload*:.
 */
@property (nonatomic, readonly) SKDownload *xy_storeDownload;

/** Used in @c storeDownloadFailed:, @c storePaymentTransactionFailed:, @c storeProductsRequestFailed:, @c storeRefreshReceiptFailed: and @c storeRestoreTransactionsFailed:.
 */
@property (nonatomic, readonly) NSError *xy_storeError;

/** Used in @c storeDownload*:, @c storePaymentTransactionFinished: and in @c storePaymentTransactionFailed:.
 */
@property (nonatomic, readonly) SKPaymentTransaction *xy_transaction;

/** Used in @c storeRestoreTransactionsFinished:.
 */
@property (nonatomic, readonly) NSArray *xy_transactions;

@end

