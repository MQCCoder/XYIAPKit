//
//  XYInAppReceipt.h
//  Pods
//
//  Created by qichao.ma on 2018/5/3.
//

#import <Foundation/Foundation.h>

/**
 具体苹果返回字段见最下方
 */
@interface XYInAppReceipt : NSObject

/**
 The default value is 1, the minimum value is 1, and the maximum value is 10.
 */
@property (nonatomic, assign) NSInteger quantity;

@property (nonatomic, copy) NSString *product_id;

@property (nonatomic, copy) NSString *transaction_id;

@property (nonatomic, copy) NSString *original_transaction_id;

@property (nonatomic, strong) NSDate *purchase_date;

@property (nonatomic, strong) NSDate *original_purchase_date;

/**
 仅用于，自动续费订阅
 true，表示处于 免费试用 时期
 如果已有票据中含有is_trial_period或者is_in_intro_offer_period为true，用户不再具备有此项资格
 
 For a subscription, whether or not it is in the free trial period.
 This key is only present for auto-renewable subscription receipts. The value for this key is "true" if the customer’s subscription is currently in the free trial period, or "false" if not.
 
 Note: If a previous subscription period in the receipt has the value “true” for either the is_trial_period or the is_in_intro_offer_period key, the user is not eligible for a free trial or introductory price within that subscription group.
 */
@property (nonatomic, assign) BOOL is_trial_period;

//**********************以上为四种内购类型公共字段，下面字段为自动续期订阅独有字段*********************

/**
 This key is only present for auto-renewable subscription receipts.
 Use this value to identify the date when the subscription will renew or expire, to determine if a customer should have access to content or service.
 After validating the latest receipt, if the subscription expiration date for the latest renewal transaction is a past date, it is safe to assume that the subscription has expired.
 
 */
@property (nonatomic, strong) NSDate *expires_date;

/**
 “1” - Customer canceled their subscription.
 “2” - Billing error; for example customer’s payment information was no longer valid.
 “3” - Customer did not agree to a recent price increase.
 “4” - Product was not available for purchase at the time of renewal.
 “5” - Unknown error
 */
@property (nonatomic, assign) NSInteger expiration_intent;

/**
 对于订阅过期的自动续费产品，苹果是否会尝试自动续费
 For an expired subscription, whether or not Apple is still attempting to automatically renew the subscription.
 “1” - App Store is still attempting to renew the subscription.
 “0” - App Store has stopped attempting to renew the subscription.
 
 This key is only present for auto-renewable subscription receipts. If the customer’s subscription failed to renew because the App Store was unable to complete the transaction, this value will reflect whether or not the App Store is still trying to renew the subscription.
 */
@property (nonatomic, assign) BOOL is_in_billing_retry_period;

/**
 仅用于，自动续费订阅
 true，表示处于 引导价格 时期
 如果已有票据中含有is_trial_period或者is_in_intro_offer_period为true，用户不再具备有此项资格
 
 For an auto-renewable subscription, whether or not it is in the introductory price period.
 This key is only present for auto-renewable subscription receipts. The value for this key is "true" if the customer’s subscription is currently in an introductory price period, or "false" if not.
 
 Note: If a previous subscription period in the receipt has the value “true” for either the is_trial_period or the is_in_intro_offer_period key, the user is not eligible for a free trial or introductory price within that subscription group.
 */
@property (nonatomic, assign) BOOL is_in_intro_offer_period;

/**
 退款操作时间
 For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
 Treat a canceled receipt the same as if no purchase had ever been made.
 A canceled in-app purchase remains in the receipt indefinitely. Only applicable if the refund was for a non-consumable product, an auto-renewable subscription, a non-renewing subscription, or for a free subscription.
 */
@property (nonatomic, strong) NSDate *cancellation_date;


/**
 内购取消的原因
 “1” - Customer canceled their transaction due to an actual or perceived issue within your app.
 
 “0” - Transaction was canceled for another reason, for example, if the customer made the purchase accidentally.
 
 Use this value along with the cancellation date to identify possible issues in your app that may lead customers to contact Apple customer support.
 */
@property (nonatomic, copy) NSString *cancellation_reason;

/**
 APP唯一标识符
 */
@property (nonatomic, copy) NSString *app_item_id;

/**
 This key is not present for receipts created in the test environment. Use this value to identify the version of the app that the customer bought
 */
@property (nonatomic, copy) NSString *version_external_identifier;

/**
 This value is a unique ID that identifies purchase events across devices, including subscription renewal purchase events.
 */
@property (nonatomic, copy) NSString *web_order_line_item_id;

/**
 The current renewal status for the auto-renewable subscription.
 “1” - Subscription will renew at the end of the current subscription period.
 
 “0” - Customer has turned off automatic renewal for their subscription.
 
 This key is only present for auto-renewable subscription receipts, for active or expired subscriptions. The value for this key should not be interpreted as the customer’s subscription status. You can use this value to display an alternative subscription product in your app, for example, a lower level subscription plan that the customer can downgrade to from their current plan.
 
 */
@property (nonatomic, assign) NSInteger auto_renew_status;

/**
 The current renewal preference for the auto-renewable subscription.
 This key is only present for auto-renewable subscription receipts. The value for this key corresponds to the productIdentifier property of the product that the customer’s subscription renews. You can use this value to present an alternative service level to the customer before the current subscription period ends.
 */
@property (nonatomic, copy) NSString *auto_renew_product_id;

/**
 The current price consent status for a subscription price increase.
 “1” - Customer has agreed to the price increase. Subscription will renew at the higher price.
 
 “0” - Customer has not taken action regarding the increased price. Subscription expires if the customer takes no action before the renewal date.
 
 This key is only present for auto-renewable subscription receipts if the subscription price was increased without keeping the existing price for active subscribers. You can use this value to track customer adoption of the new price and take appropriate action.
 */
@property (nonatomic, assign) NSInteger price_consent_status;


@end


/**
 
 自定续期订阅
 {
 "expires_date" = "2018-05-04 11:11:09 Etc/GMT";
 "expires_date_ms" = 1525432269000;
 "expires_date_pst" = "2018-05-04 04:11:09 America/Los_Angeles";
 "is_in_intro_offer_period" = false;
 "is_trial_period" = false;
 "original_purchase_date" = "2018-05-04 10:11:10 Etc/GMT";
 "original_purchase_date_ms" = 1525428670000;
 "original_purchase_date_pst" = "2018-05-04 03:11:10 America/Los_Angeles";
 "original_transaction_id" = 1000000356225087;
 "product_id" = 1312830469;
 "purchase_date" = "2018-05-04 10:11:09 Etc/GMT";
 "purchase_date_ms" = 1525428669000;
 "purchase_date_pst" = "2018-05-04 03:11:09 America/Los_Angeles";
 quantity = 1;
 "transaction_id" = 1000000395911972;
 "web_order_line_item_id" = 1000000038645384;
 }
 
 非自动续期
 {
 "is_trial_period" = false;
 "original_purchase_date" = "2018-05-04 10:13:23 Etc/GMT";
 "original_purchase_date_ms" = 1525428803000;
 "original_purchase_date_pst" = "2018-05-04 03:13:23 America/Los_Angeles";
 "original_transaction_id" = 1000000395914364;
 "product_id" = 1003;
 "purchase_date" = "2018-05-04 10:13:23 Etc/GMT";
 "purchase_date_ms" = 1525428803000;
 "purchase_date_pst" = "2018-05-04 03:13:23 America/Los_Angeles";
 quantity = 1;
 "transaction_id" = 1000000395914364;
 }
 
 */
