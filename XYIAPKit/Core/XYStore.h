//
//  XYStore.h
//  Pods
//
//  Created by qichao.ma on 2018/4/19.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "XYStoreProtocol.h"
#import "NSNotification+XYStore.h"

extern NSString *const XYStoreErrorDomain;
extern NSInteger const XYStoreErrorCodeDownloadCanceled;
extern NSInteger const XYStoreErrorCodeUnknownProductIdentifier;
extern NSInteger const XYStoreErrorCodeUnableToCompleteVerification;


@interface XYStore : NSObject<SKPaymentTransactionObserver>

+ (XYStore*)defaultStore;

+ (BOOL)canMakePayments;

- (void)addPayment:(NSString*)productIdentifier;

- (void)addPayment:(NSString*)productIdentifier
           success:(void (^)(SKPaymentTransaction *transaction))successBlock
           failure:(void (^)(SKPaymentTransaction *transaction, NSError *error))failureBlock;

- (void)addPayment:(NSString*)productIdentifier
              user:(NSString*)userIdentifier
           success:(void (^)(SKPaymentTransaction *transaction))successBlock
           failure:(void (^)(SKPaymentTransaction *transaction, NSError *error))failureBlock;


/**
 请求在线商品，并存储于内存中

 @param identifiers 产品id
 */
- (void)requestProducts:(NSSet*)identifiers;

/**
 请求在线商品，并存储于内存中

 @param identifiers 产品id
 */
- (void)requestProducts:(NSSet*)identifiers
                success:(void (^)(NSArray *products, NSArray *invalidProductIdentifiers))successBlock
                failure:(void (^)(NSError *error))failureBlock;

/**
 获取单个产品，若内存中已存在，直接返回；若没有则网络获取
 
 @param identifier 产品id
 */
- (void)fetchProduct:(NSString *)identifier
             success:(void (^)(SKProduct *product))success
             failure:(void (^)(NSError *error))failure;


/**
 恢复购买
 */
- (void)restoreTransactions;

- (void)restoreTransactionsOnSuccess:(void (^)(NSArray *transactions))successBlock
                             failure:(void (^)(NSError *error))failureBlock;

- (void)restoreTransactionsOfUser:(NSString*)userIdentifier
                        onSuccess:(void (^)(NSArray *transactions))successBlock
                          failure:(void (^)(NSError *error))failureBlock;

#pragma mark Receipt

+ (NSURL*)receiptURL;

- (void)refreshReceipt;

- (void)refreshReceiptOnSuccess:(void (^)(void))successBlock
                        failure:(void (^)(NSError *error))failureBlock;


/**
 获取base64的票据，主要用于服务器的票据校验
 */
- (void)base64Receipt:(void(^)(NSString *base64Data))success
              failure:(void(^)(NSError *error))failure;

/**
 外部内容下载
 
 @discussion Hosted content from Apple’s server (SKDownload) 自动下载，无需设置contentDownloader。
 */
@property (nonatomic, weak) id<XYStoreContentDownloader> contentDownloader;

/**
 票据校验
 */
@property (nonatomic, weak) id<XYStoreReceiptVerifier> receiptVerifier;

/**
 The transaction persistor. It is recommended to provide your own obfuscator if piracy is a concern. The store will use weak obfuscation via `NSKeyedArchiver` by default.
 @see XYStoreKeychainPersistence
 @see XYStoreUserDefaultsPersistence
 */
@property (nonatomic, weak) id<XYStoreTransactionPersistor> transactionPersistor;


#pragma mark Product management

- (SKProduct*)productForIdentifier:(NSString*)productIdentifier;

+ (NSString*)localizedPriceOfProduct:(SKProduct*)product;

#pragma mark Notifications

/** Adds an observer to the store.
 Unlike `SKPaymentQueue`, it is not necessary to set an observer.
 @param observer The observer to add.
 */
- (void)addStoreObserver:(id<XYStoreObserver>)observer;

/** Removes an observer from the store.
 @param observer The observer to remove.
 */
- (void)removeStoreObserver:(id<XYStoreObserver>)observer;

@end



