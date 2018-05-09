//
//  XYiTunesReceipt.h
//  Pods
//
//  Created by qichao.ma on 2018/5/2.
//

#import <Foundation/Foundation.h>
#import "XYInAppReceipt.h"

@interface XYiTunesReceipt : NSObject

@property (nonatomic, copy) NSString *adam_id;

@property (nonatomic, copy) NSString *app_item_id;

@property (nonatomic, copy) NSString *application_version;

@property (nonatomic, copy) NSString *bundle_id;

@property (nonatomic, copy) NSString *download_id;

/**
 In the JSON file, the value of this key is an array containing all in-app purchase receipts based on the in-app purchase transactions present in the input base-64 receipt-data. For receipts containing auto-renewable subscriptions, check the value of the latest_receipt_info key to get the status of the most recent renewal.
 
 Note: An empty array is a valid receipt.
 
 The in-app purchase receipt for a consumable product is added to the receipt when the purchase is made. It is kept in the receipt until your app finishes that transaction. After that point, it is removed from the receipt the next time the receipt is updated - for example, when the user makes another purchase or if your app explicitly refreshes the receipt.
 
 The in-app purchase receipt for a non-consumable product, auto-renewable subscription, non-renewing subscription, or free subscription remains in the receipt indefinitely.
 */
@property (nonatomic, strong) NSArray<XYInAppReceipt *> *in_app;

@property (nonatomic, copy) NSString *original_application_version;

@property (nonatomic, strong) NSDate *original_purchase_date;

@property (nonatomic, strong) NSDate *receipt_creation_date;

@property (nonatomic, strong) NSDate *request_date;

@property (nonatomic, copy) NSString *receipt_type;

@property (nonatomic, copy) NSString *version_external_identifier;

@end
