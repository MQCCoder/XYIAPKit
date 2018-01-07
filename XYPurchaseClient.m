//
//  XYPurchaseClient.m
//  Pods
//
//  Created by qichao.ma on 2017/12/19.
//

#import "XYPurchaseClient.h"
#import <objc/runtime.h>
#import "XYReceiptHandler.h"
#import "NSUserDefaults+XYSafeAccess.h"

#define XY_PRE_IAP_PRODUCT_INFO         @"xy_pre_iap_product_info"

@interface XYPurchaseClient()<SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    NSArray *_productIdentifiers;
}

@property (nonatomic, strong) XYIAPObserveHandler *observerHandler;

@property (nonatomic, assign) BOOL sandbox;//是否是沙盒环境用于内测试

@property (nonatomic, assign) NSInteger purchaseRetryCurrentCount;

@property (nonatomic, strong) XYReceiptHandler *receiptHandler;

@property (nonatomic, copy) XYIAPResponseBlock responseBlock;

@property (nonatomic, copy) XYIAPPurchaseBlock purchaseBlock;

@property (nonatomic, copy) XYIAPRestorePurchaseBlock restorePurchaseBlock;

@property (nonatomic, strong) SKProductsResponse *productsResponse;

@property (nonatomic, assign) BOOL isSubscribe;

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, copy) NSString *sharedscretKey;

@end

@implementation XYPurchaseClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initAll];
    }
    return self;
}

- (void)initAll{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    self.purchaseRetryCurrentCount = 1;
    self.purchaseRetryCount = 3;
    self.sandbox = NO;
#ifdef DEBUG
    self.sandbox = YES;
#endif
}

#pragma mark - Observer

+ (void)registerObserver:(id<XYIAPObserveProtocol>)observer {
    [[XYIAPObserveHandler shareInstance] registerObserver:observer];
}

+ (void)unregisterObserver:(id<XYIAPObserveProtocol>)observer {
    [[XYIAPObserveHandler shareInstance] unregisterObserver:observer];
}

// 票据校验
- (void)receiptCheck
{
    if (self.isSubscribe) {
        [self.receiptHandler checkSubscribeRecieptWithIdentifier:self.identifier sharedscretKey:self.sharedscretKey isSandbox:self.sandbox block:^(BOOL isValid) {
            
        }];
    }else {
        [self.receiptHandler checkPurchaseRecieptWithIdentifier:nil isSandbox:YES block:^(BOOL isValid) {
            
        }];
    }
        
    
}

#pragma mark - Products

- (void)requestProductsWithProductIdentifiers:(NSArray *)productIdentifiers block:(XYIAPResponseBlock)block
{
    if (!productIdentifiers || [productIdentifiers count] == 0) {
        return;
    }
    
    self.responseBlock = block;
    if ([SKPaymentQueue canMakePayments]) {
        
        NSSet * set = [NSSet setWithArray:productIdentifiers];
        SKProductsRequest * request = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
        request.delegate = self;
        [request start];
        
    }else {
        NSLog(@"失败，用户禁止应用内付费购买.");
        if (block) {
            block(XYIAPRequestResultNoPermission);
        }
    }
}

- (void)subscribe:(NSString *)iapProductId sharedscretKey:(NSString *)sharedscretKey block:(XYIAPPurchaseBlock)block
{
    self.isSubscribe = YES;
    self.sharedscretKey = sharedscretKey;
    [self buy:iapProductId block:block];
}

- (void)purchase:(NSString *)iapProductId block:(XYIAPPurchaseBlock)block
{
    self.isSubscribe = NO;
    [self buy:iapProductId block:block];
}

#pragma mark - 购买
- (void)buy:(NSString *)iapProductId block:(XYIAPPurchaseBlock)block
{
    if (!iapProductId) {
        return;
    }
    
    self.purchaseBlock = block;
    
    __weak typeof(self) weakSelf = self;
    void(^completeHandler)(void) = ^(void){
        
        SKProduct *productToBePurchased = [weakSelf skProductWithIdentifier:iapProductId];
        if (!productToBePurchased || ![productToBePurchased isKindOfClass:[SKProduct class]]) {
            if (block) {
                block(XYIAPPurchaseResultFailedNoProduct);
            }
            
            return;
        }
        
        SKPayment * payment = [SKPayment paymentWithProduct:productToBePurchased];
        if (!payment) {
            
            if (block) {
                block(XYIAPPurchaseResultFailedCreatePayment);
            }
            
            return;
        }
        
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    };
    
    if ([self isValidProduct:iapProductId]) {
        completeHandler();
    }else {
        [self requestProductsWithProductIdentifiers:@[iapProductId] block:^( XYIAPRequestResult result) {
            
            if (result == XYIAPRequestResultNoPermission) {
                // 用户不允许
                if (block) {
                    block(XYIAPPurchaseResultFailedNoPermission);
                }
            }else if(result == XYIAPRequestResultSuccess) {
                completeHandler();
            }else {
                // 查询失败
                if (block) {
                    block(XYIAPPurchaseResultFailedNoProduct);
                }
            }
        }];
    }
}

#pragma mark - restore
- (void)restorePurchases:(XYIAPRestorePurchaseBlock)block
{
    self.restorePurchaseBlock = block;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - SKProductsRequestDelegate
// 以上查询的回调函数
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    if (!response.products || response.products == 0) {
        NSLog(@"无法获取产品信息");
        if (self.responseBlock) {
            self.responseBlock(XYIAPRequestResultFailed);
        }
        return;
    }
    
    self.productsResponse = response;
    // 存储查询的商品信息
    [self saveProductsInfo:response];
    
    if (self.responseBlock) {
        self.responseBlock(XYIAPRequestResultSuccess);
    }
}

#pragma mark - Transaction Observer
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased://交易完成
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed://交易失败
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored://已经购买过该商品
                [self restoreTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:      //商品添加进列表
                NSLog(@"商品添加进列表");
                break;
            default:
                break;
        }
    }
}

// Sent when transactions are removed from the queue (via finishTransaction:).
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    
}

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"paymentQueue restoreCompletedTransactionsFailedWithError ===>");
    if (self.restorePurchaseBlock) {
        self.restorePurchaseBlock(XYIAPRestorePurchaseResultFailed);
    }
}

// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"paymentQueue paymentQueueRestoreCompletedTransactionsFinished ===>");
    if (queue.transactions.count == 0) {
        if (self.restorePurchaseBlock) {
            self.restorePurchaseBlock(XYIAPRestorePurchaseResultSuccessNoPurchased);
        }
    }else {
        /// 票据校验
        [self receiptCheck];
        
        if (self.restorePurchaseBlock) {
            self.restorePurchaseBlock(XYIAPRestorePurchaseResultSuccessAllCompleted);
        }
    }
}

// Sent when the download state has changed.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads
{
    
}

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product {
    return YES;
}

#pragma mark - Transaction Result

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    if(transaction){
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }

    if (self.purchaseBlock) {
        self.purchaseBlock(XYIAPPurchaseResultSuccess);
    }
    
    // 票据校验
    [self receiptCheck];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    // 对于已购商品，处理恢复购买的逻辑
    if(transaction){
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }
    
    if (self.restorePurchaseBlock) {
        self.restorePurchaseBlock(XYIAPRestorePurchaseResultSuccess);
    }
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if(transaction){
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }
    if(!transaction || transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"购买失败");
        if (self.purchaseBlock) {
            self.purchaseBlock(XYIAPPurchaseResultFailed);
        }
    } else {
        NSLog(@"用户取消交易");
        if (self.purchaseBlock) {
            self.purchaseBlock(XYIAPPurchaseResultFailedCanceled);
        }
    }
}

#pragma mark - Tool

- (BOOL)isValidProduct:(NSString *)identifier
{
    NSArray<SKProduct *> *products = [self validProducts];
    
    BOOL isValid = NO;
    for (SKProduct *product in products) {
        if ([identifier isEqualToString:product.productIdentifier]) {
            isValid = YES;
            break;
        }
    }
    
    return isValid;
}

- (NSArray<SKProduct *> *)validProducts
{
    SKProductsResponse *response = self.productsResponse;
    
    NSMutableArray *validProducts = [NSMutableArray array];
    for (SKProduct *product in response.products) {
        if ([response.invalidProductIdentifiers containsObject:product.productIdentifier] == NO) {
            [validProducts addObject:product];
        }
    }
    
    return validProducts;
}

- (SKProduct *)skProductWithIdentifier:(NSString *)identifier
{
    SKProductsResponse *response = self.productsResponse;
    
    SKProduct *skProduct;
    for (SKProduct *product in response.products) {
        if ([product.productIdentifier isEqualToString:identifier]) {
            skProduct = product;
            break;
        }
    }
    
    return skProduct;
}

- (void)saveProductsInfo:(SKProductsResponse *)response
{
    for (SKProduct *product in response.products) {
        XYIAPProductInfo *info = [self productInfoWithSKProduct:product];
        
        NSString *key = [self productPreKey:product.productIdentifier];
        [NSUserDefaults xy_setArcObject:info forKey:key];
    }
}

- (NSString *)productPreKey:(NSString *)identifier
{
    return [NSString stringWithFormat:@"%@_%@", XY_PRE_IAP_PRODUCT_INFO, identifier];
}

- (XYIAPProductInfo *)productInfoWithSKProduct:(SKProduct *)skProduct
{
    if (skProduct) {
        XYIAPProductInfo *productInfo = [[XYIAPProductInfo alloc] init];
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehaviorDefault];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:skProduct.priceLocale];
        productInfo.productLocalePrice = [numberFormatter stringFromNumber:skProduct.price];//$0.99
        productInfo.productTitle = skProduct.localizedTitle;
        productInfo.productDesc  = skProduct.localizedDescription;
        productInfo.productId = skProduct.productIdentifier;
        productInfo.productRawPrice = [skProduct.price stringValue];//0.99
        productInfo.productCurrency = [numberFormatter currencyCode];//USD
        productInfo.productLocaleIdentifier = skProduct.priceLocale.localeIdentifier;
        
        return productInfo;
    }
    
    return nil;
}

- (XYIAPProductInfo *)productInfoWithIdentifier:(NSString *)identifier
{
    XYIAPProductInfo *info;
    SKProduct *product = [self skProductWithIdentifier:identifier];
    if (product) {
        info =  [self productInfoWithSKProduct:product];
    }else {
        info = [NSUserDefaults xy_arcObjectForKey:[self productPreKey:identifier]];
    }
    
    return info;
}


#pragma mark - lazy load

- (XYIAPObserveHandler *)observerHandler
{
    if (!_observerHandler) {
        _observerHandler = [[XYIAPObserveHandler alloc] init];
    }
    
    return _observerHandler;
}

- (XYReceiptHandler *)receiptHandler
{
    if (!_receiptHandler) {
        _receiptHandler = [[XYReceiptHandler alloc] init];
    }
    
    return _receiptHandler;
}

@end
