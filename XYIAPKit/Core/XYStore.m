//
//  XYStore.m
//  Pods
//
//  Created by qichao.ma on 2018/4/19.
//

#import "XYStore.h"
#import "XYStoreProductService.h"
#import "XYReceiptRefreshService.h"

NSString *const XYStoreErrorDomain = @"com.quvideo.store";
NSInteger const XYStoreErrorCodeDownloadCanceled = 300;
NSInteger const XYStoreErrorCodeUnknownProductIdentifier = 100;
NSInteger const XYStoreErrorCodeUnableToCompleteVerification = 200;

NSString* const XYSKDownloadCanceled = @"XYSKDownloadCanceled";
NSString* const XYSKDownloadFailed = @"XYSKDownloadFailed";
NSString* const XYSKDownloadFinished = @"XYSKDownloadFinished";
NSString* const XYSKDownloadPaused = @"XYSKDownloadPaused";
NSString* const XYSKDownloadUpdated = @"XYSKDownloadUpdated";
NSString* const XYSKPaymentTransactionDeferred = @"XYSKPaymentTransactionDeferred";
NSString* const XYSKPaymentTransactionFailed = @"XYSKPaymentTransactionFailed";
NSString* const XYSKPaymentTransactionFinished = @"XYSKPaymentTransactionFinished";
NSString* const XYSKProductsRequestFailed = @"XYSKProductsRequestFailed";
NSString* const XYSKProductsRequestFinished = @"XYSKProductsRequestFinished";
NSString* const XYSKRefreshReceiptFailed = @"XYSKRefreshReceiptFailed";
NSString* const XYSKRefreshReceiptFinished = @"XYSKRefreshReceiptFinished";
NSString* const XYSKRestoreTransactionsFailed = @"XYSKRestoreTransactionsFailed";
NSString* const XYSKRestoreTransactionsFinished = @"XYSKRestoreTransactionsFinished";

typedef void (^XYSKPaymentTransactionFailureBlock)(SKPaymentTransaction *transaction, NSError *error);
typedef void (^XYSKPaymentTransactionSuccessBlock)(SKPaymentTransaction *transaction);
typedef void (^XYStoreFailureBlock)(NSError *error);
typedef void (^XYStoreSuccessBlock)(void);

@interface XYAddPaymentParameters : NSObject

@property (nonatomic, strong) XYSKPaymentTransactionSuccessBlock successBlock;

@property (nonatomic, strong) XYSKPaymentTransactionFailureBlock failureBlock;

@end

@implementation XYAddPaymentParameters

@end

@interface XYStore()<SKRequestDelegate>
{
    NSInteger _pendingRestoredTransactionsCount;
    BOOL _restoredCompletedTransactionsFinished;
    
    void (^_restoreTransactionsFailureBlock)(NSError* error);
    void (^_restoreTransactionsSuccessBlock)(NSArray* transactions);
}

// HACK: We use a dictionary of product identifiers because the returned SKPayment is different from the one we add to the queue. Bad Apple.
@property (nonatomic, strong) NSMutableDictionary *addPaymentParameters;

@property (nonatomic, strong) NSMutableDictionary *products;

@property (nonatomic, strong) NSMutableArray *restoredTransactions;

@property (nonatomic, strong) NSMutableSet *productsRequestSet;

@property (nonatomic, strong) XYReceiptRefreshService *receiptService;

@property (nonatomic, weak) id<XYStoreContentDownloader> contentDownloader;

@property (nonatomic, weak) id<XYStoreReceiptVerifier> receiptVerifier;

@property (nonatomic, weak) id<XYStoreTransactionPersistor> transactionPersistor;

@end

@implementation XYStore

- (instancetype) init
{
    if (self = [super init])
    {
        _restoredTransactions = [NSMutableArray array];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

+ (XYStore *)defaultStore
{
    static XYStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (void)registerContentDownloader:(id<XYStoreContentDownloader>)contentDownloader
{
    _contentDownloader = contentDownloader;
}

- (void)registerReceiptVerifier:(id<XYStoreReceiptVerifier>)receiptVerifier
{
    _receiptVerifier = receiptVerifier;
}

- (void)registerTransactionPersistor:(id<XYStoreTransactionPersistor>)transactionPersistor
{
    _transactionPersistor = transactionPersistor;
}

#pragma mark StoreKit wrapper

+ (BOOL)canMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

- (void)addPayment:(NSString*)productIdentifier
{
    [self addPayment:productIdentifier success:nil failure:nil];
}

- (void)addPayment:(NSString*)productIdentifier
           success:(void (^)(SKPaymentTransaction *transaction))successBlock
           failure:(void (^)(SKPaymentTransaction *transaction, NSError *error))failureBlock
{
    [self addPayment:productIdentifier user:nil success:successBlock failure:failureBlock];
}

- (void)addPayment:(NSString*)productIdentifier
              user:(NSString*)userIdentifier
           success:(void (^)(SKPaymentTransaction *transaction))successBlock
           failure:(void (^)(SKPaymentTransaction *transaction, NSError *error))failureBlock
{
    
    __weak typeof(self) weakSelf = self;
    void(^errorBlock)(NSError *error)  = ^(NSError *error) {
        if (failureBlock) {
            failureBlock(nil, error);
        }
    };
    
    id completeBlock = ^(SKProduct *product) {
        if (!product) {
            NSString *errorDesc = NSLocalizedStringFromTable(@"Unknown product identifier", @"XYIAPKit", @"Error description");
            NSError *error = [NSError errorWithDomain:XYStoreErrorDomain
                                                 code:XYStoreErrorCodeUnknownProductIdentifier
                                             userInfo:@{NSLocalizedDescriptionKey: errorDesc}];
            errorBlock(error);
        }else {
            SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
            if ([payment respondsToSelector:@selector(setApplicationUsername:)])
            {
                payment.applicationUsername = userIdentifier;
            }
            
            XYAddPaymentParameters *parameters = [[XYAddPaymentParameters alloc] init];
            parameters.successBlock = successBlock;
            parameters.failureBlock = failureBlock;
            weakSelf.addPaymentParameters[productIdentifier] = parameters;
            
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    };
    
    [self fetchProduct:productIdentifier success:completeBlock failure:errorBlock];
}

#pragma mark - requestProducts
- (void)requestProducts:(NSSet*)identifiers
{
    [self requestProducts:identifiers success:nil failure:nil];
}

- (void)requestProducts:(NSSet*)identifiers
                success:(void (^)(NSArray *products, NSArray *invalidProductIdentifiers))successBlock
                failure:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    XYStoreProductService *service = [[XYStoreProductService alloc] init];
    service.addProductBlock = ^(SKProduct *product) {
        [weakSelf addProduct:product];
    };
    
    service.removeProductRequestBlock = ^(XYStoreProductService *service) {
        [weakSelf removeProductsRequest:service];
    };
    
    [self.productsRequestSet addObject:service];
    
    [service requestProducts:identifiers
                     success:^(NSArray *products, NSArray *invalidIdentifiers)
     {
         
         if (successBlock) {
             successBlock(products, invalidIdentifiers);
         }
         
         NSDictionary *userInfo = @{XYStoreNotificationProducts: products, XYStoreNotificationInvalidProductIdentifiers: invalidIdentifiers};
         [[NSNotificationCenter defaultCenter] postNotificationName:XYSKProductsRequestFinished object:nil userInfo:userInfo];
         
     } failure:^(NSError *error) {
         
         if (failureBlock) {
             failureBlock(error);
         }
         
         NSDictionary *userInfo = nil;
         if (error){
             // error might be nil (e.g., on airplane mode)
             userInfo = @{XYStoreNotificationStoreError: error};
         }
         [[NSNotificationCenter defaultCenter] postNotificationName:XYSKProductsRequestFailed object:nil userInfo:userInfo];
     }];
}


- (void)fetchProduct:(NSString *)identifier
             success:(void (^)(SKProduct *product))success
             failure:(void (^)(NSError *error))failure
{
    if (!identifier) {
        NSString *errorDesc = NSLocalizedStringFromTable(@"Unknown product identifier", @"XYIAPKit", @"Error description");
        NSError *error = [NSError errorWithDomain:XYStoreErrorDomain
                                             code:XYStoreErrorCodeUnknownProductIdentifier
                                         userInfo:@{NSLocalizedDescriptionKey: errorDesc}];
        if (failure) {
            failure(error);
        }
        return;
    }
    
    SKProduct *product = [self productForIdentifier:identifier];
    if (product) {
        success(product);
        return;
    }
    
    // 若内存中没有，网络获取
    NSSet *set = [[NSSet alloc] initWithArray:@[identifier]];
    [self requestProducts:set
                  success:^(NSArray *products, NSArray *invalidProductIdentifiers)
     {
         if (products.count > 0) {
             if (success) {
                 success(products.firstObject);
             }
         }
     } failure:failure];
}

- (void)restoreTransactions
{
    [self restoreTransactionsOnSuccess:nil failure:nil];
}

- (void)restoreTransactionsOnSuccess:(void (^)(NSArray *transactions))successBlock
                             failure:(void (^)(NSError *error))failureBlock
{
    _restoredCompletedTransactionsFinished = NO;
    _pendingRestoredTransactionsCount = 0;
    _restoredTransactions = [NSMutableArray array];
    _restoreTransactionsSuccessBlock = successBlock;
    _restoreTransactionsFailureBlock = failureBlock;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)restoreTransactionsOfUser:(NSString*)userIdentifier
                        onSuccess:(void (^)(NSArray *transactions))successBlock
                          failure:(void (^)(NSError *error))failureBlock
{
    NSAssert([[SKPaymentQueue defaultQueue] respondsToSelector:@selector(restoreCompletedTransactionsWithApplicationUsername:)], @"restoreCompletedTransactionsWithApplicationUsername: not supported in this iOS version. Use restoreTransactionsOnSuccess:failure: instead.");
    _restoredCompletedTransactionsFinished = NO;
    _pendingRestoredTransactionsCount = 0;
    _restoreTransactionsSuccessBlock = successBlock;
    _restoreTransactionsFailureBlock = failureBlock;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactionsWithApplicationUsername:userIdentifier];
}

#pragma mark Receipt

+ (NSURL*)receiptURL
{
    NSAssert(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1, @"appStoreReceiptURL not supported in this iOS version.");
    NSURL *url = [NSBundle mainBundle].appStoreReceiptURL;
    return url;
}

- (void)refreshReceipt
{
    [self refreshReceiptOnSuccess:nil failure:nil];
}

- (void)refreshReceiptOnSuccess:(XYStoreSuccessBlock)successBlock
                        failure:(XYStoreFailureBlock)failureBlock
{
    [self.receiptService refreshReceiptOnSuccess:^{
        if (successBlock) {
            successBlock();
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:XYSKRefreshReceiptFinished object:self];
        
    } failure:^(NSError *error) {
        if (failureBlock) {
            failureBlock(error);
        }
        
        NSDictionary *userInfo = nil;
        if (error) {
            userInfo = @{XYStoreNotificationStoreError: error};
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:XYSKRefreshReceiptFailed object:self userInfo:userInfo];
    }];
}

- (void)base64Receipt:(void(^)(NSString *base64Data))success
              failure:(void(^)(NSError *error))failure
{
    void(^handler)(NSURL *url) = ^(NSURL *url) {
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSString *base64Data = [data base64EncodedStringWithOptions:0];
        if (success) {
            success(base64Data);
        }
    };
    
    NSURL *URL = [NSBundle mainBundle].appStoreReceiptURL;
    if (URL) {
        handler(URL);
    }else {
        [self refreshReceiptOnSuccess:^{
            NSURL *URL = [NSBundle mainBundle].appStoreReceiptURL;
            if (URL) {
                handler(URL);
            }else {
                if (failure) {
                    failure([NSError errorWithDomain:@"com.iapkit" code:100001 userInfo:@{NSLocalizedDescriptionKey : @"None appStoreReceiptUR"}]);
                }
            }
        } failure:failure];
    }
}

#pragma mark Product management

- (SKProduct*)productForIdentifier:(NSString*)productIdentifier
{
    return self.products[productIdentifier];
}

+ (NSString*)localizedPriceOfProduct:(SKProduct*)product
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    numberFormatter.locale = product.priceLocale;
    NSString *formattedString = [numberFormatter stringFromNumber:product.price];
    return formattedString;
}

#pragma mark Observers

- (void)addStoreObserver:(id<XYStoreObserver>)observer
{
    [self addStoreObserver:observer selector:@selector(storeDownloadCanceled:) notificationName:XYSKDownloadCanceled];
    [self addStoreObserver:observer selector:@selector(storeDownloadFailed:) notificationName:XYSKDownloadFailed];
    [self addStoreObserver:observer selector:@selector(storeDownloadFinished:) notificationName:XYSKDownloadFinished];
    [self addStoreObserver:observer selector:@selector(storeDownloadPaused:) notificationName:XYSKDownloadPaused];
    [self addStoreObserver:observer selector:@selector(storeDownloadUpdated:) notificationName:XYSKDownloadUpdated];
    [self addStoreObserver:observer selector:@selector(storeProductsRequestFailed:) notificationName:XYSKProductsRequestFailed];
    [self addStoreObserver:observer selector:@selector(storeProductsRequestFinished:) notificationName:XYSKProductsRequestFinished];
    [self addStoreObserver:observer selector:@selector(storePaymentTransactionDeferred:) notificationName:XYSKPaymentTransactionDeferred];
    [self addStoreObserver:observer selector:@selector(storePaymentTransactionFailed:) notificationName:XYSKPaymentTransactionFailed];
    [self addStoreObserver:observer selector:@selector(storePaymentTransactionFinished:) notificationName:XYSKPaymentTransactionFinished];
    [self addStoreObserver:observer selector:@selector(storeRefreshReceiptFailed:) notificationName:XYSKRefreshReceiptFailed];
    [self addStoreObserver:observer selector:@selector(storeRefreshReceiptFinished:) notificationName:XYSKRefreshReceiptFinished];
    [self addStoreObserver:observer selector:@selector(storeRestoreTransactionsFailed:) notificationName:XYSKRestoreTransactionsFailed];
    [self addStoreObserver:observer selector:@selector(storeRestoreTransactionsFinished:) notificationName:XYSKRestoreTransactionsFinished];
}

- (void)removeStoreObserver:(id<XYStoreObserver>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKDownloadCanceled object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKDownloadFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKDownloadFinished object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKDownloadPaused object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKDownloadUpdated object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKProductsRequestFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKProductsRequestFinished object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKPaymentTransactionDeferred object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKPaymentTransactionFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKPaymentTransactionFinished object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKRefreshReceiptFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKRefreshReceiptFinished object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKRestoreTransactionsFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:XYSKRestoreTransactionsFinished object:self];
}

// Private
- (void)addStoreObserver:(id<XYStoreObserver>)observer selector:(SEL)aSelector notificationName:(NSString*)notificationName
{
    if ([observer respondsToSelector:aSelector])
    {
        [[NSNotificationCenter defaultCenter] addObserver:observer selector:aSelector name:notificationName object:self];
    }
}

#pragma mark SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self didPurchaseTransaction:transaction queue:queue];
                break;
            case SKPaymentTransactionStateFailed:
                [self didFailTransaction:transaction queue:queue error:transaction.error];
                break;
            case SKPaymentTransactionStateRestored:
                [self didRestoreTransaction:transaction queue:queue];
                break;
            case SKPaymentTransactionStateDeferred:
                [self didDeferTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"restore transactions finished");
    _restoredCompletedTransactionsFinished = YES;
    
    [self notifyRestoreTransactionFinishedIfApplicableAfterTransaction:nil];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"restored transactions failed with error %@", error.debugDescription);
    if (_restoreTransactionsFailureBlock != nil)
    {
        _restoreTransactionsFailureBlock(error);
        _restoreTransactionsFailureBlock = nil;
    }
    NSDictionary *userInfo = nil;
    if (error) {
        userInfo = @{XYStoreNotificationStoreError: error};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:XYSKRestoreTransactionsFailed object:self userInfo:userInfo];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads
{
    for (SKDownload *download in downloads)
    {
        switch (download.downloadState)
        {
            case SKDownloadStateActive:
                [self didUpdateDownload:download queue:queue];
                break;
            case SKDownloadStateCancelled:
                [self didCancelDownload:download queue:queue];
                break;
            case SKDownloadStateFailed:
                [self didFailDownload:download queue:queue];
                break;
            case SKDownloadStateFinished:
                [self didFinishDownload:download queue:queue];
                break;
            case SKDownloadStatePaused:
                [self didPauseDownload:download queue:queue];
                break;
            case SKDownloadStateWaiting:
                // Do nothing
                break;
        }
    }
}

#pragma mark Download State

- (void)didCancelDownload:(SKDownload*)download queue:(SKPaymentQueue*)queue
{
    SKPaymentTransaction *transaction = download.transaction;
    NSLog(@"download %@ for product %@ canceled", download.contentIdentifier, download.transaction.payment.productIdentifier);
    
    [self postNotificationWithName:XYSKDownloadCanceled download:download userInfoExtras:nil];
    
    NSError *error = [NSError errorWithDomain:XYStoreErrorDomain code:XYStoreErrorCodeDownloadCanceled userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"Download canceled", @"XYStore", @"Error description")}];
    
    const BOOL hasPendingDownloads = [self.class hasPendingDownloadsInTransaction:transaction];
    if (!hasPendingDownloads)
    {
        [self didFailTransaction:transaction queue:queue error:error];
    }
}

- (void)didFailDownload:(SKDownload*)download queue:(SKPaymentQueue*)queue
{
    NSError *error = download.error;
    SKPaymentTransaction *transaction = download.transaction;
    NSLog(@"download %@ for product %@ failed with error %@", download.contentIdentifier, transaction.payment.productIdentifier, error.debugDescription);
    
    NSDictionary *extras = error ? @{XYStoreNotificationStoreError : error} : nil;
    [self postNotificationWithName:XYSKDownloadFailed download:download userInfoExtras:extras];
    
    const BOOL hasPendingDownloads = [self.class hasPendingDownloadsInTransaction:transaction];
    if (!hasPendingDownloads)
    {
        [self didFailTransaction:transaction queue:queue error:error];
    }
}

- (void)didFinishDownload:(SKDownload*)download queue:(SKPaymentQueue*)queue
{
    SKPaymentTransaction *transaction = download.transaction;
    NSLog(@"download %@ for product %@ finished", download.contentIdentifier, transaction.payment.productIdentifier);
    
    [self postNotificationWithName:XYSKDownloadFinished download:download userInfoExtras:nil];
    
    const BOOL hasPendingDownloads = [self.class hasPendingDownloadsInTransaction:transaction];
    if (!hasPendingDownloads)
    {
        [self finishTransaction:download.transaction queue:queue];
    }
}

- (void)didPauseDownload:(SKDownload*)download queue:(SKPaymentQueue*)queue
{
    NSLog(@"download %@ for product %@ paused", download.contentIdentifier, download.transaction.payment.productIdentifier);
    [self postNotificationWithName:XYSKDownloadPaused download:download userInfoExtras:nil];
}

- (void)didUpdateDownload:(SKDownload*)download queue:(SKPaymentQueue*)queue
{
    NSLog(@"download %@ for product %@ updated", download.contentIdentifier, download.transaction.payment.productIdentifier);
    NSDictionary *extras = @{XYStoreNotificationDownloadProgress : @(download.progress)};
    [self postNotificationWithName:XYSKDownloadUpdated download:download userInfoExtras:extras];
}

+ (BOOL)hasPendingDownloadsInTransaction:(SKPaymentTransaction*)transaction
{
    for (SKDownload *download in transaction.downloads)
    {
        switch (download.downloadState)
        {
            case SKDownloadStateActive:
            case SKDownloadStatePaused:
            case SKDownloadStateWaiting:
                return YES;
            case SKDownloadStateCancelled:
            case SKDownloadStateFailed:
            case SKDownloadStateFinished:
                continue;
        }
    }
    return NO;
}

#pragma mark Transaction State

- (void)didPurchaseTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue*)queue
{
    NSLog(@"transaction purchased with product %@", transaction.payment.productIdentifier);
    if (self.receiptVerifier != nil)
    {
        [self.receiptVerifier verifyTransaction:transaction success:^{
            [self didVerifyTransaction:transaction queue:queue];
        } failure:^(NSError *error) {
            [self didFailTransaction:transaction queue:queue error:error];
        }];
    }
    else
    {
        NSLog(@"WARNING: no receipt verification");
        [self didVerifyTransaction:transaction queue:queue];
    }
}

- (void)didFailTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue*)queue error:(NSError*)error
{
    SKPayment *payment = transaction.payment;
    NSString* productIdentifier = payment.productIdentifier;
    NSLog(@"transaction failed with product %@ and error %@", productIdentifier, error.debugDescription);
    
    if (error.code != XYStoreErrorCodeUnableToCompleteVerification)
    { // If we were unable to complete the verification we want StoreKit to keep reminding us of the transaction
        [queue finishTransaction:transaction];
    }
    
    XYAddPaymentParameters *parameters = [self popAddPaymentParametersForIdentifier:productIdentifier];
    if (parameters.failureBlock != nil)
    {
        parameters.failureBlock(transaction, error);
    }
    
    NSDictionary *extras = error ? @{XYStoreNotificationStoreError : error} : nil;
    [self postNotificationWithName:XYSKPaymentTransactionFailed transaction:transaction userInfoExtras:extras];
    
    if (transaction.transactionState == SKPaymentTransactionStateRestored)
    {
        [self notifyRestoreTransactionFinishedIfApplicableAfterTransaction:transaction];
    }
}

- (void)didRestoreTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue*)queue
{
    NSLog(@"transaction restored with product %@", transaction.originalTransaction.payment.productIdentifier);
    
    _pendingRestoredTransactionsCount++;
    if (self.receiptVerifier != nil)
    {
        [self.receiptVerifier verifyTransaction:transaction success:^{
            [self didVerifyTransaction:transaction queue:queue];
        } failure:^(NSError *error) {
            [self didFailTransaction:transaction queue:queue error:error];
        }];
    }
    else
    {
        NSLog(@"WARNING: no receipt verification");
        [self didVerifyTransaction:transaction queue:queue];
    }
}

- (void)didDeferTransaction:(SKPaymentTransaction *)transaction
{
    [self postNotificationWithName:XYSKPaymentTransactionDeferred transaction:transaction userInfoExtras:nil];
}

- (void)didVerifyTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue*)queue
{
    if (self.contentDownloader != nil)
    {
        [self.contentDownloader downloadContentForTransaction:transaction success:^{
            [self postNotificationWithName:XYSKDownloadFinished transaction:transaction userInfoExtras:nil];
            [self didDownloadSelfHostedContentForTransaction:transaction queue:queue];
        } progress:^(float progress) {
            NSDictionary *extras = @{XYStoreNotificationDownloadProgress : @(progress)};
            [self postNotificationWithName:XYSKDownloadUpdated transaction:transaction userInfoExtras:extras];
        } failure:^(NSError *error) {
            NSDictionary *extras = error ? @{XYStoreNotificationStoreError : error} : nil;
            [self postNotificationWithName:XYSKDownloadFailed transaction:transaction userInfoExtras:extras];
            [self didFailTransaction:transaction queue:queue error:error];
        }];
    } else {
        [self didDownloadSelfHostedContentForTransaction:transaction queue:queue];
    }
}

- (void)didDownloadSelfHostedContentForTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue*)queue
{
    NSArray *downloads = [transaction respondsToSelector:@selector(downloads)] ? transaction.downloads : @[];
    if (downloads.count > 0)
    {
        NSLog(@"starting downloads for product %@ started", transaction.payment.productIdentifier);
        [queue startDownloads:downloads];
    }
    else
    {
        [self finishTransaction:transaction queue:queue];
    }
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue*)queue
{
    SKPayment *payment = transaction.payment;
    NSString* productIdentifier = payment.productIdentifier;
    [queue finishTransaction:transaction];
    [self.transactionPersistor persistTransaction:transaction];
    
    XYAddPaymentParameters *wrapper = [self popAddPaymentParametersForIdentifier:productIdentifier];
    if (wrapper.successBlock != nil)
    {
        wrapper.successBlock(transaction);
    }
    
    [self postNotificationWithName:XYSKPaymentTransactionFinished transaction:transaction userInfoExtras:nil];
    
    if (transaction.transactionState == SKPaymentTransactionStateRestored)
    {
        [self notifyRestoreTransactionFinishedIfApplicableAfterTransaction:transaction];
    }
}

- (void)notifyRestoreTransactionFinishedIfApplicableAfterTransaction:(SKPaymentTransaction*)transaction
{
    if (transaction != nil)
    {
        [_restoredTransactions addObject:transaction];
        _pendingRestoredTransactionsCount--;
    }
    if (_restoredCompletedTransactionsFinished && _pendingRestoredTransactionsCount == 0)
    { // Wait until all restored transations have been verified
        NSArray *restoredTransactions = [_restoredTransactions copy];
        if (_restoreTransactionsSuccessBlock != nil)
        {
            _restoreTransactionsSuccessBlock(restoredTransactions);
            _restoreTransactionsSuccessBlock = nil;
        }
        NSDictionary *userInfo = @{ XYStoreNotificationTransactions : restoredTransactions };
        [[NSNotificationCenter defaultCenter] postNotificationName:XYSKRestoreTransactionsFinished object:self userInfo:userInfo];
    }
}

- (XYAddPaymentParameters*)popAddPaymentParametersForIdentifier:(NSString*)identifier
{
    XYAddPaymentParameters *parameters = self.addPaymentParameters[identifier];
    [self.addPaymentParameters removeObjectForKey:identifier];
    return parameters;
}

#pragma mark Private

- (void)addProduct:(SKProduct*)product
{
    self.products[product.productIdentifier] = product;
}

- (void)postNotificationWithName:(NSString*)notificationName download:(SKDownload*)download userInfoExtras:(NSDictionary*)extras
{
    NSMutableDictionary *mutableExtras = extras ? [NSMutableDictionary dictionaryWithDictionary:extras] : [NSMutableDictionary dictionary];
    mutableExtras[XYStoreNotificationStoreDownload] = download;
    [self postNotificationWithName:notificationName transaction:download.transaction userInfoExtras:mutableExtras];
}

- (void)postNotificationWithName:(NSString*)notificationName transaction:(SKPaymentTransaction*)transaction userInfoExtras:(NSDictionary*)extras
{
    NSString *productIdentifier = transaction.payment.productIdentifier;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[XYStoreNotificationTransaction] = transaction;
    userInfo[XYStoreNotificationProductIdentifier] = productIdentifier;
    if (extras) {
        [userInfo addEntriesFromDictionary:extras];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:userInfo];
}

- (void)removeProductsRequest:(XYStoreProductService *)request
{
    [self.productsRequestSet removeObject:request];
}

#pragma mark - lazy load

- (NSMutableSet *)productsRequestSet
{
    if (!_productsRequestSet) {
        _productsRequestSet = [NSMutableSet set];
    }
    
    return _productsRequestSet;
}

- (XYReceiptRefreshService *)receiptService
{
    if (_receiptService) {
        _receiptService = [[XYReceiptRefreshService alloc] init];
    }
    
    return _receiptService;
}

- (NSMutableDictionary *)addPaymentParameters
{
    if (!_addPaymentParameters) {
        _addPaymentParameters = [NSMutableDictionary dictionary];
    }
    
    return _addPaymentParameters;
}

- (NSMutableDictionary *)products
{
    if (!_products) {
        _products = [NSMutableDictionary dictionary];
    }
    
    return _products;
}

@end

