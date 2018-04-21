//
//  XYStoreAppReceiptVerifier.m
//  Pods
//
//  Created by qichao.ma on 2018/4/19.
//

#import "XYStoreAppReceiptVerifier.h"
#import "XYAppReceipt.h"

@implementation XYStoreAppReceiptVerifier

- (void)verifyTransaction:(SKPaymentTransaction*)transaction
                  success:(void (^)(void))successBlock
                  failure:(void (^)(NSError *error))failureBlock
{
    XYAppReceipt *receipt = [XYAppReceipt bundleReceipt];
    const BOOL verified = [self verifyTransaction:transaction
                                        inReceipt:receipt
                                          success:successBlock
                                          failure:nil]; // nil，为了下面的再次验证
    if (verified) return;
    
    // 刷新票据，再次认证
    [[XYStore defaultStore] refreshReceiptOnSuccess:^{
        XYAppReceipt *receipt = [XYAppReceipt bundleReceipt];
        [self verifyTransaction:transaction
                      inReceipt:receipt
                        success:successBlock
                        failure:failureBlock];
    } failure:^(NSError *error) {
        [self failWithBlock:failureBlock error:error];
    }];
}

- (BOOL)verifyAppReceipt
{
    XYAppReceipt *receipt = [XYAppReceipt bundleReceipt];
    return [self verifyAppReceipt:receipt];
}

#pragma mark - Properties

- (NSString*)bundleIdentifier
{
    if (!_bundleIdentifier)
    {
        return [NSBundle mainBundle].bundleIdentifier;
    }
    return _bundleIdentifier;
}

- (NSString*)bundleVersion
{
    if (!_bundleVersion)
    {
#if TARGET_OS_IPHONE
        return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
#else
        return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#endif
    }
    return _bundleVersion;
}

#pragma mark - Private

- (BOOL)verifyAppReceipt:(XYAppReceipt*)receipt
{
    if (!receipt) return NO;
    
    if (![receipt.bundleIdentifier isEqualToString:self.bundleIdentifier]) return NO;
    
    if (![receipt.appVersion isEqualToString:self.bundleVersion]) return NO;
    
    if (![receipt verifyReceiptHash]) return NO;
    
    return YES;
}

- (BOOL)verifyTransaction:(SKPaymentTransaction*)transaction
                inReceipt:(XYAppReceipt*)receipt
                  success:(void (^)(void))successBlock
                  failure:(void (^)(NSError *error))failureBlock
{
    const BOOL receiptVerified = [self verifyAppReceipt:receipt];
    if (!receiptVerified)
    {
        [self failWithBlock:failureBlock
                    message:@"The app receipt failed verification"];
        return NO;
    }
    SKPayment *payment = transaction.payment;
    const BOOL transactionVerified = [receipt containsInAppPurchaseOfProductIdentifier:payment.productIdentifier];
    if (!transactionVerified)
    {
        [self failWithBlock:failureBlock
                    message:@"The app receipt does not contain the given product"];
        return NO;
    }
    if (successBlock)
    {
        successBlock();
    }
    return YES;
}

- (void)failWithBlock:(void (^)(NSError *error))failureBlock message:(NSString*)message
{
    NSError *error = [NSError errorWithDomain:XYStoreErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : message}];
    [self failWithBlock:failureBlock error:error];
}

- (void)failWithBlock:(void (^)(NSError *error))failureBlock error:(NSError*)error
{
    if (failureBlock)
    {
        failureBlock(error);
    }
}

@end
