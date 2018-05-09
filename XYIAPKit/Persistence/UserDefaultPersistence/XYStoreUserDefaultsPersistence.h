//
//  XYStoreUserDefaultsPersistence.h
//  Pods
//
//  Created by qichao.ma on 2018/4/19.
//

#import <Foundation/Foundation.h>
#import "XYStore.h"
@class XYStoreTransaction;

@interface XYStoreUserDefaultsPersistence : NSObject<XYStoreTransactionPersistor>

+ (instancetype)shareInstance;

/** Remove all transactions from user defaults.
 */
- (void)removeTransactions;

/** Consume the given product if available. Intended for consumable products.
 @param productIdentifier Identifier of the product to be consumed.
 @return YES if the product was consumed, NO otherwise.
 */
- (BOOL)consumeProductOfIdentifier:(NSString*)productIdentifier;

/** Returns the number of transactions for the given product that have not been consumed. Intended for consumable products.
 @return The number of transactions for the given product that have not been consumed.
 */
- (NSInteger)countProductOfdentifier:(NSString*)productIdentifier;

/**
 Indicates wheter the given product has been purchased. Intended for non-consumables.
 @param productIdentifier Identifier of the product.
 @return YES if there is at least one transaction for the given product, NO otherwise. Note that if the product is consumable this method will still return YES even if all transactions have been consumed.
 */
- (BOOL)isPurchasedProductOfIdentifier:(NSString*)productIdentifier;

/** Returns the product identifiers of all products that have a transaction.
 */
- (NSSet*)purchasedProductIdentifiers;

/**
 Returns all the transactions for the given product.
 @param productIdentifier Identifier of the product whose transactions will be returned.
 @return An array of XYStoreTransaction objects (not SKPaymentTransaction) for the given product.
 @see XYStoreTransaction
 */
- (NSArray*)transactionsForProductOfIdentifier:(NSString*)productIdentifier;

@end

/** Subclasess should override these methods to use their own obfuscation.
 */
@interface XYStoreUserDefaultsPersistence(Obfuscation)

/** Returns a data representation of the given transaction. The default implementation uses NSKeyedArchiver.
 @param transaction Transaction to be converted into data
 @return Data representation of the given transaction
 */
- (NSData*)dataWithTransaction:(XYStoreTransaction*)transaction;

/** Returns a transaction from the given data. The default implementation uses NSKeyedUnarchiver.
 @param data Data from which a transaction will be obtained
 @return Transaction from the given data
 */
- (XYStoreTransaction*)transactionWithData:(NSData*)data;

@end
