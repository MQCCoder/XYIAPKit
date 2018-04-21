//
//  XYStoreTransaction.m
//  Pods
//
//  Created by qichao.ma on 2018/4/19.
//

#import "XYStoreTransaction.h"

NSString* const XYStoreCoderConsumedKey = @"consumed";
NSString* const XYStoreCoderProductIdentifierKey = @"productIdentifier";
NSString* const XYStoreCoderTransactionDateKey = @"transactionDate";
NSString* const XYStoreCoderTransactionIdentifierKey = @"transactionIdentifier";
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
NSString* const XYStoreCoderTransactionReceiptKey = @"transactionReceipt";
#endif

@implementation XYStoreTransaction

- (instancetype)initWithPaymentTransaction:(SKPaymentTransaction*)paymentTransaction
{
    if (self = [super init])
    {
        _productIdentifier = paymentTransaction.payment.productIdentifier;
        _transactionDate = paymentTransaction.transactionDate;
        _transactionIdentifier = paymentTransaction.transactionIdentifier;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
        _transactionReceipt = paymentTransaction.transactionReceipt;
#endif
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        _consumed = [decoder decodeBoolForKey:XYStoreCoderConsumedKey];
        _productIdentifier = [decoder decodeObjectForKey:XYStoreCoderProductIdentifierKey];
        _transactionDate = [decoder decodeObjectForKey:XYStoreCoderTransactionDateKey];
        _transactionIdentifier = [decoder decodeObjectForKey:XYStoreCoderTransactionIdentifierKey];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
        _transactionReceipt = [decoder decodeObjectForKey:XYStoreCoderTransactionReceiptKey];
#endif
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:self.consumed forKey:XYStoreCoderConsumedKey];
    [coder encodeObject:self.productIdentifier forKey:XYStoreCoderProductIdentifierKey];
    [coder encodeObject:self.transactionDate forKey:XYStoreCoderTransactionDateKey];
    if (self.transactionIdentifier != nil) { [coder encodeObject:self.transactionIdentifier forKey:XYStoreCoderTransactionIdentifierKey]; }
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    if (self.transactionReceipt != nil) { [coder encodeObject:self.transactionReceipt forKey:XYStoreCoderTransactionReceiptKey]; }
#endif
}

@end
