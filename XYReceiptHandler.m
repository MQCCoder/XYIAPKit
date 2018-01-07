//
//  XYReceiptHandler.m
//  Pods
//
//  Created by qichao.ma on 2017/12/22.
//

#import "XYReceiptHandler.h"
#import <StoreKit/StoreKit.h>

typedef void (^IAPCheckReceiptCompleteResponseBlock)(id response, NSError *error);

typedef void (^IAPRefreshReceiptCompleteBlock)(void);

@interface XYReceiptHandler()<SKProductsRequestDelegate>

@property (nonatomic, copy) IAPRefreshReceiptCompleteBlock refreshCompleteBlock;

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, copy) NSString *sharedscretKey;

@property (nonatomic, copy) IAPCheckReceiptCompleteBlock completeBlock;

@property (nonatomic, assign) BOOL isSandbox;

@property (nonatomic, assign) BOOL isSubscribe;

@end

@implementation XYReceiptHandler

- (void)checkSubscribeRecieptWithIdentifier:(NSString *)identifier
                             sharedscretKey:(NSString *)sharedscretKey
                                  isSandbox:(BOOL)isSandbox
                                      block:(IAPCheckReceiptCompleteBlock)block
{
    self.identifier = identifier;
    self.sharedscretKey = sharedscretKey;
    self.completeBlock = block;
    self.isSandbox = isSandbox;
    self.isSubscribe = YES;
    
    [self checkReceipt];
}

- (void)checkPurchaseRecieptWithIdentifier:(NSString *)identifier
                                 isSandbox:(BOOL)isSandbox
                                     block:(IAPCheckReceiptCompleteBlock)block
{
    self.identifier = identifier;
    self.sharedscretKey = nil;
    self.completeBlock = block;
    self.isSandbox = isSandbox;
    self.isSubscribe = NO;
    
    [self checkReceipt];
}

- (void)checkReceipt
{
    NSString *iapReceipt = [self iapReceipt];
    if (iapReceipt) {
        [self handleReceiptWithIapReceipt:iapReceipt];
    }else {
        // 刷新票据
        SKReceiptRefreshRequest *refreshReceiptRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:@{}];
        refreshReceiptRequest.delegate = self;
        [refreshReceiptRequest start];
        
        __weak typeof(self) weakSelf = self;
        self.refreshCompleteBlock = ^(){
            NSString *iapReceipt = [weakSelf iapReceipt];
            if (iapReceipt) {
                [weakSelf handleReceiptWithIapReceipt:iapReceipt];
            }
        };
    }
}

- (void)handleReceiptWithIapReceipt:(NSString *)iapReceipt
{
    __weak typeof(self) weakSelf = self;
    
    void(^completeHandler)(id response, NSError *error) = ^(id response, NSError *error) {
        
        NSDictionary *jsonResponse = response;
        if (weakSelf.isSubscribe) {
            
            [weakSelf currentInternetDate:^(NSDate *date) {
                BOOL isValidSubscribed = [weakSelf checkIsValidSubscribe:date response:jsonResponse];
                
                if (weakSelf.completeBlock) {
                    weakSelf.completeBlock(isValidSubscribed);
                }
            }];
        }else {
            
            BOOL isValid = NO;
            if (!error) {
                isValid = YES;
            }
            
            if (weakSelf.completeBlock) {
                weakSelf.completeBlock(isValid);
            }
        }
    };
    
    [self checkReceiptWithIapReceipt:iapReceipt
                        onCompletion:completeHandler
                           isSandbox:self.isSandbox];
}

- (BOOL)checkIsValidSubscribe:(NSDate *)date response:(NSDictionary *)response
{
    long long expirationTime = [self expirationDateFromResponse:response productId:self.identifier];
    BOOL isCurrentInfoValid = [self checkIsCurrentInfoValid:response productId:self.identifier];
    BOOL isRenewInfoValid = [self checkIsRenewInfoValid:response productId:self.identifier];
    NSDate *expireDate = [NSDate dateWithTimeIntervalSince1970:expirationTime/1000];
    
    NSTimeInterval timeInterval = [expireDate timeIntervalSinceDate:date];
    
    BOOL isValidSubscribed = NO;
    if (timeInterval > 0 && isCurrentInfoValid) {
        //有效
        isValidSubscribed = YES;
    } else if (isRenewInfoValid) {
        isValidSubscribed = YES;
    }
    
    return isValidSubscribed;
}

- (void)checkReceiptWithIapReceipt:(NSString *)iapReceipt
                      onCompletion:(IAPCheckReceiptCompleteResponseBlock)completion
                         isSandbox:(BOOL)isSandbox
{
    NSError *jsonError = nil;
    NSMutableDictionary *receiptData = [NSMutableDictionary dictionary];
    [receiptData setValue:iapReceipt forKey:@"receipt-data"];
    [receiptData setValue:self.sharedscretKey forKey:@"password"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:receiptData
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError
                        ];
    
    NSURL *requestURL = nil;
    if(isSandbox)
    {
        requestURL = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
    }else {
        requestURL = [NSURL URLWithString:@"https://buy.itunes.apple.com/verifyReceipt"];
    }
    
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:jsonData];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:req queue:queue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
        if (connectionError) {
            /* ... Handle error ... */
            if (completion) {
                completion(nil, connectionError);
            }
        } else {
            NSError *error;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:0
                                                                           error:&error
                                          ];
            
            if (!jsonResponse) {
                /* ... Handle error ...*/
                if (completion) {
                    completion(nil, error);
                }
            }else {
                
                /* ... Send a response back to the device ... */
                NSNumber *value = jsonResponse[@"status"];
                if (value) {
                    NSInteger status = value.integerValue;
                    if (status == 21007) {
                        [self checkReceiptWithIapReceipt:iapReceipt
                                            onCompletion:completion
                                               isSandbox:YES];
                        return;
                    }
                }
                
                if (completion) {
                    completion(jsonResponse, connectionError);
                }
            }
        }
    }];
}

- (void)currentInternetDate:(void (^)(NSDate *date))block
{
    NSString *urlString = @"https://m.baidu.com";
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString: urlString]];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval: 2];
    [request setHTTPShouldHandleCookies:FALSE];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
        //如果没有网络，直接返回手机时间
        NSDate *curDate = [NSDate date];
        BOOL isError = NO;
        if (connectionError) {
            /* ... Handle error ... */
            isError = YES;
        } else {
            
            if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSString *date = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Date"];
                NSDateFormatter *dMatter = [[NSDateFormatter alloc] init];
                dMatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                [dMatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
                
                NSDate *netDate = [dMatter dateFromString:date];
                curDate = netDate;
            }
        }
        
        if (block) {
            block(curDate);
        }
    }];
}

#pragma mark - receipt parse
- (NSString *)iapReceipt
{
    NSString *receiptString = nil;
    NSURL *rereceiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[rereceiptURL path]]) {
        NSData *receiptData = [NSData dataWithContentsOfURL:rereceiptURL];
        receiptString = [receiptData base64EncodedStringWithOptions:0];
    }
    
    return receiptString;
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    
}

- (void)requestDidFinish:(SKRequest *)request {
    if([request isKindOfClass:[SKReceiptRefreshRequest class]])
    {
        if (self.refreshCompleteBlock) {
            self.refreshCompleteBlock();
        }
    }
}

#pragma mark - Receipt 解析苹果返回的票据验证信息

- (BOOL)checkIsCurrentInfoValid:(NSDictionary *)jsonResponse productId:(NSString *)productId {
    NSArray *renewalInfos = jsonResponse[@"pending_renewal_info"];
    if (renewalInfos && renewalInfos.count > 0) {
        for (NSDictionary *renewalInfo in renewalInfos) {
            NSString *curProductId = renewalInfo[@"product_id"];
            if ([curProductId isEqualToString:productId]) {
                //校验状态
                NSNumber *status = renewalInfo[@"auto_renew_status"];
                NSNumber *expiration_intent = renewalInfo[@"expiration_intent"];
                //                NSNumber *is_in_billing_retry_period = renewalInfo[@"is_in_billing_retry_period"];
                
                if (status.intValue == 0 && expiration_intent) {
                } else {
                    /*
                     * 当前订阅状态为 已停止续费 （status为 0）
                     * 当前订阅续费存在停止原因 （expiration_intent）
                     * 则当前订阅已过期
                     */
                    return YES;
                }
                
                break;
            }
        }
    }
    
    return NO;
}

- (BOOL)checkIsRenewInfoValid:(NSDictionary *)jsonResponse productId:(NSString *)productId {
    NSArray *renewalInfos = jsonResponse[@"pending_renewal_info"];
    if (renewalInfos && renewalInfos.count > 0) {
        for (NSDictionary *renewalInfo in renewalInfos) {
            NSString *curProductId = renewalInfo[@"product_id"];
            NSString *renewProductId = renewalInfo[@"auto_renew_product_id"];
            NSNumber *status = renewalInfo[@"auto_renew_status"];
            
            if ([renewProductId isEqualToString:productId] && ![curProductId isEqualToString:renewProductId]) {
                if (status.intValue == 1) {
                    /*
                     * 当前订阅状态为 正常（status为 1）
                     * 订阅存在续费订单（renewProductId），且和当前订单（curProductId）不是同一商品
                     * 则认为renewProductId是降级后的续费产品，为有效预订产品，视为已购买
                     */
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

- (long long)expirationDateFromResponse:(NSDictionary *)jsonResponse productId:(NSString *)productId {
    
    NSArray *receiptInfos = jsonResponse[@"latest_receipt_info"];
    if (receiptInfos && receiptInfos.count > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"product_id = %@", productId];
        NSArray *array = [receiptInfos filteredArrayUsingPredicate:predicate];
        
        if (array && array.count > 0) {
            NSDictionary *lastReceipt = array.lastObject;
            NSNumber *expiresMs = lastReceipt[@"expires_date_ms"];
            
            return expiresMs.longLongValue;
        }
    }
    
    return 0;
}

#pragma mark - Tool
- (BOOL)iap_isEmptyString:(NSString *)string;
{
    // Note that [string length] == 0 can be false when [string isEqualToString:@""] is true, because these are Unicode strings.
    
    if (((NSNull *) string == [NSNull null]) || (string == nil) || ![string isKindOfClass:(NSString.class)]) {
        return YES;
    }
    
    string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([string isEqualToString:@""]) {
        return YES;
    }
    
    return NO;
}


@end
