//
//  XYStoreUserDefaultsPersistence.m
//  Pods
//
//  Created by qichao.ma on 2018/4/19.
//

#import "XYStoreUserDefaultsPersistence.h"
#import "XYStoreTransaction.h"

NSString* const XYStoreTransactionsUserDefaultsKey = @"XYStoreTransactions";

@implementation XYStoreUserDefaultsPersistence

+ (instancetype)shareInstance
{
    static XYStoreUserDefaultsPersistence *shareInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[XYStoreUserDefaultsPersistence alloc] init];
    });
    
    return shareInstance;
}

#pragma mark - XYStoreTransactionPersistor

- (void)persistTransaction:(SKPaymentTransaction*)paymentTransaction
{
    NSUserDefaults *defaults = [self userDefaults];
    NSDictionary *purchases = [defaults objectForKey:XYStoreTransactionsUserDefaultsKey] ? : @{};
    
    SKPayment *payment = paymentTransaction.payment;
    NSString *productIdentifier = payment.productIdentifier;
    
    NSArray *transactions = purchases[productIdentifier] ? : @[];
    NSMutableArray *updatedTransactions = [NSMutableArray arrayWithArray:transactions];
    
    XYStoreTransaction *transaction = [[XYStoreTransaction alloc] initWithPaymentTransaction:paymentTransaction];
    NSData *data = [self dataWithTransaction:transaction];
    [updatedTransactions addObject:data];
    [self setTransactions:updatedTransactions forProductIdentifier:productIdentifier];
}

#pragma mark - Public

- (void)removeTransactions
{
    NSUserDefaults *defaults = [self userDefaults];
    [defaults removeObjectForKey:XYStoreTransactionsUserDefaultsKey];
    [defaults synchronize];
}

- (BOOL)consumeProductOfIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [self userDefaults];
    NSDictionary *purchases = [defaults objectForKey:XYStoreTransactionsUserDefaultsKey] ? : @{};
    NSArray *transactions = purchases[productIdentifier] ? : @[];
    for (NSData *data in transactions)
    {
        XYStoreTransaction *transaction = [self transactionWithData:data];
        if (!transaction.consumed)
        {
            transaction.consumed = YES;
            NSData *updatedData = [self dataWithTransaction:transaction];
            NSMutableArray *updatedTransactions = [NSMutableArray arrayWithArray:transactions];
            NSInteger index = [updatedTransactions indexOfObject:data];
            updatedTransactions[index] = updatedData;
            [self setTransactions:updatedTransactions forProductIdentifier:productIdentifier];
            return YES;
        }
    }
    return NO;
}

- (NSInteger)countProductOfdentifier:(NSString*)productIdentifier
{
    NSArray *transactions = [self transactionsForProductOfIdentifier:productIdentifier];
    NSInteger count = 0;
    for (XYStoreTransaction *transaction in transactions)
    {
        if (!transaction.consumed) { count++; }
    }
    return count;
}

- (BOOL)isPurchasedProductOfIdentifier:(NSString*)productIdentifier
{
    NSArray *transactions = [self transactionsForProductOfIdentifier:productIdentifier];
    return transactions.count > 0;
}

- (NSSet*)purchasedProductIdentifiers
{
    NSUserDefaults *defaults = [self userDefaults];
    NSDictionary *purchases = [defaults objectForKey:XYStoreTransactionsUserDefaultsKey];
    NSSet *productIdentifiers = [NSSet setWithArray:purchases.allKeys];
    return productIdentifiers;
}

- (NSArray*)transactionsForProductOfIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [self userDefaults];
    NSDictionary *purchases = [defaults objectForKey:XYStoreTransactionsUserDefaultsKey];
    NSArray *obfuscatedTransactions = purchases[productIdentifier] ? : @[];
    NSMutableArray *transactions = [NSMutableArray arrayWithCapacity:obfuscatedTransactions.count];
    for (NSData *data in obfuscatedTransactions)
    {
        XYStoreTransaction *transaction = [self transactionWithData:data];
        [transactions addObject:transaction];
    }
    return transactions;
}

- (NSUserDefaults *)userDefaults
{
    return [NSUserDefaults standardUserDefaults];
}

#pragma mark - Obfuscation

- (NSData*)dataWithTransaction:(XYStoreTransaction*)transaction
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:transaction];
    [archiver finishEncoding];
    return data;
}

- (XYStoreTransaction*)transactionWithData:(NSData*)data
{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    XYStoreTransaction *transaction = [unarchiver decodeObject];
    [unarchiver finishDecoding];
    return transaction;
}

#pragma mark - Private

- (void)setTransactions:(NSArray*)transactions forProductIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [self userDefaults];
    NSDictionary *purchases = [defaults objectForKey:XYStoreTransactionsUserDefaultsKey] ? : @{};
    NSMutableDictionary *updatedPurchases = [NSMutableDictionary dictionaryWithDictionary:purchases];
    updatedPurchases[productIdentifier] = transactions;
    [defaults setObject:updatedPurchases forKey:XYStoreTransactionsUserDefaultsKey];
    [defaults synchronize];
}


@end
