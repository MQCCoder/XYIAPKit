//
//  XYiTunesResponse.h
//  Pods
//
//  Created by qichao.ma on 2018/5/2.
//

#import <Foundation/Foundation.h>
#import "XYiTunesReceipt.h"
#import "XYInAppReceipt.h"

@class XYPendingRenewalInfo;


/**
 The values of the latest_receipt and latest_receipt_info keys are useful when checking whether an auto-renewable subscription is currently active.
 
 The values of latest_expired_receipt_info key are useful when checking whether an auto-renewable subscription has expired. Use this along with the value for Subscription Expiration Intent to get the reason for expiration.
 
 By providing an app receipt or any transaction receipt for the subscription and checking these values, you can get information about the currently-active subscription period. If the receipt being validated is for the latest renewal, the value for latest_receipt is the same as receipt-data (in the request) and the value for latest_receipt_info is the same as receipt.
 */

@interface XYiTunesResponse : NSObject


/**
 For iOS 7 style app receipts, the status code is reflects the status of the app receipt as a whole. For example, if you send a valid app receipt that contains an expired subscription, the response is 0 because the receipt as a whole is valid.
 
 https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#//apple_ref/doc/uid/TP40010573-CH104-SW5
 
 Status Code
 21000    The App Store could not read the JSON object you provided.
 
 21002    The data in the receipt-data property was malformed or missing.
 
 21003    The receipt could not be authenticated.
 
 21004    The shared secret you provided does not match the shared secret on file for your account.
 
 21005    The receipt server is not currently available.
 
 21006    This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response.
 Only returned for iOS 6 style transaction receipts for auto-renewable subscriptions.
 
 21007    This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead.
 
 21008    This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead.
 
 21010    This receipt could not be authorized. Treat this the same as if a purchase was never made.
 
 21100-21199 Internal data access error.
 
 */
@property (nonatomic, assign) NSInteger status;

/**
 A JSON representation of the receipt that was sent for verification.
 For information about keys found in a receipt, see Receipt Fields.
 */
@property (nonatomic, strong) XYiTunesReceipt *receipt;

/**
 @ auto-renewable subscription
 
 Only returned for receipts containing auto-renewable subscriptions. For iOS 6 style transaction receipts, this is the base-64 encoded receipt for the most recent renewal. For iOS 7 style app receipts, this is the latest base-64 encoded app receipt.
 */
@property (nonatomic, copy) NSString *latest_receipt;

/**
 @ auto-renewable subscription
 
 Only returned for receipts containing auto-renewable subscriptions. For iOS 6 style transaction receipts, this is the JSON representation of the receipt for the most recent renewal. For iOS 7 style app receipts, the value of this key is an array containing all in-app purchase transactions. This excludes transactions for a consumable product that have been marked as finished by your app.
 */
@property (nonatomic, strong) NSArray<XYInAppReceipt *> *latest_receipt_info;

/**
 @ auto-renewable subscription
 
 Only returned for iOS 7 style app receipts containing auto-renewable subscriptions. In the JSON file, the value of this key is an array where each element contains the pending renewal information for each auto-renewable subscription identified by the Product Identifier. A pending renewal may refer to a renewal that is scheduled in the future or a renewal that failed in the past for some reason.
 */
@property (nonatomic, strong) NSArray<XYPendingRenewalInfo *> *pending_renewal_info;

@end


/**
 The values of pending_renewal_info key are useful to get critical information about any pending renewal transactions for an auto-renewable subscription.
 */
@interface XYPendingRenewalInfo : NSObject

@property (nonatomic, copy) NSString *auto_renew_product_id;

@property (nonatomic, copy) NSString *original_transaction_id;

@property (nonatomic, copy) NSString *product_id;

/**
 “1” - Subscription will renew at the end of the current subscription period.
 
 “0” - Customer has turned off automatic renewal for their subscription.
 */
@property (nonatomic, assign) NSInteger auto_renew_status;

@end
