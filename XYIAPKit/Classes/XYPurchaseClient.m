//
//  XYPurchaseClient.m
//  Pods
//
//  Created by qichao.ma on 2017/12/19.
//

#import "XYPurchaseClient.h"
#import <objc/runtime.h>
#import "XYReceiptHandler.h"

@interface XYPurchaseClient()<SKPaymentTransactionObserver>

@property (nonatomic, strong) XYIAPObserveHandler *observerHandler;

@property (nonatomic, assign) BOOL sandbox;//是否是沙盒环境用于内测试

@property (nonatomic, assign) NSInteger purchaseRetryCurrentCount;

@property (nonatomic, strong) XYReceiptHandler *receiptHandler;

@property (nonatomic, copy) XYIAPPurchaseBlock purchaseBlock;

@property (nonatomic, copy) XYIAPRestorePurchaseBlock restorePurchaseBlock;

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

+ (void)requestProductsWithProductIdentifiers:(NSArray *)productIdentifiers block:(XYIAPResponseBlock)block
{
    [[XYIAPManager shareInstance] requestProductsWithProductIdentifiers:productIdentifiers block:block];
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
    
    void(^completeHandler)(void) = ^(void){
        
        SKProduct *productToBePurchased = [[XYIAPManager shareInstance] skProductWithIdentifier:iapProductId];
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
    
    if ([[XYIAPManager shareInstance] isValidProduct:iapProductId]) {
        completeHandler();
    }else {
        [[XYIAPManager shareInstance] requestProductsWithProductIdentifiers:@[iapProductId] block:^( XYIAPRequestResult result) {
            
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
