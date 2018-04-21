//
//  NSNotification+XYStore.m
//  Pods
//
//  Created by qichao.ma on 2018/4/20.
//

#import "NSNotification+XYStore.h"

NSString* const XYStoreNotificationInvalidProductIdentifiers = @"invalidProductIdentifiers";
NSString* const XYStoreNotificationDownloadProgress = @"downloadProgress";
NSString* const XYStoreNotificationProductIdentifier = @"productIdentifier";
NSString* const XYStoreNotificationProducts = @"products";
NSString* const XYStoreNotificationStoreDownload = @"storeDownload";
NSString* const XYStoreNotificationStoreError = @"storeError";
NSString* const XYStoreNotificationStoreReceipt = @"storeReceipt";
NSString* const XYStoreNotificationTransaction = @"transaction";
NSString* const XYStoreNotificationTransactions = @"transactions";

@implementation NSNotification (XYStore)

- (float)xy_downloadProgress
{
    return [self.userInfo[XYStoreNotificationDownloadProgress] floatValue];
}

- (NSArray*)xy_invalidProductIdentifiers
{
    return (self.userInfo)[XYStoreNotificationInvalidProductIdentifiers];
}

- (NSString*)xy_productIdentifier
{
    return (self.userInfo)[XYStoreNotificationProductIdentifier];
}

- (NSArray*)xy_products
{
    return (self.userInfo)[XYStoreNotificationProducts];
}

- (SKDownload*)xy_storeDownload
{
    return (self.userInfo)[XYStoreNotificationStoreDownload];
}

- (NSError*)xy_storeError
{
    return (self.userInfo)[XYStoreNotificationStoreError];
}

- (SKPaymentTransaction*)xy_transaction
{
    return (self.userInfo)[XYStoreNotificationTransaction];
}

- (NSArray*)xy_transactions {
    return (self.userInfo)[XYStoreNotificationTransactions];
}

@end
