//
//  XYStoreiTunesReceiptVerifier.m
//  Pods
//
//  Created by qichao.ma on 2018/5/2.
//

#import "XYStoreiTunesReceiptVerifier.h"
#import "XYStore.h"
#import "YYModel.h"
#import "XYiTunesResponse.h"

NSString *const XYStoreiTunesVerifyReceiptURL = @"https://buy.itunes.apple.com/verifyReceipt";

NSString *const XYStoreiTunesSandboxVerifyReceiptURL = @"https://sandbox.itunes.apple.com/verifyReceipt";

NSString *const XYCachePreferenceKeyPrefix = @"xy_cache_pre_key_prefix";

@interface XYStoreiTunesReceiptVerifier()

@property (nonatomic, strong) NSMutableDictionary *verifiedReceipts;

@end

@implementation XYStoreiTunesReceiptVerifier

+ (instancetype)shareInstance
{
    static XYStoreiTunesReceiptVerifier *shareInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[XYStoreiTunesReceiptVerifier alloc] init];
    });
    
    return shareInstance;
}

- (BOOL)isSubscribedWithAutoRenewProduct:(NSString *)productId
{
    return [self isSubscribedWithAutoRenewProduct:productId applicationUsername:nil];
}

- (BOOL)isSubscribedWithAutoRenewProduct:(NSString *)productId applicationUsername:(NSString *)applicationUsername
{
    XYiTunesResponse *iTunesResponse = [self iTunesResponseInfoWithProductId:productId applicationUsername:applicationUsername];
    if (!iTunesResponse) {
        return NO;
    }
    
    // 无票据信息直接返回NO
    if (!iTunesResponse.latest_receipt_info || iTunesResponse.latest_receipt_info.count <= 0) {
        return NO;
    }
    
    return [self checkIsSubscribed:iTunesResponse productId:productId];
}

- (BOOL)checkIsSubscribed:(XYiTunesResponse *)iTunesResponse productId:(NSString *)productId
{
    NSDate *expires_date;
    for (XYInAppReceipt *appReceipt in iTunesResponse.latest_receipt_info) {
        
        if ([appReceipt.product_id isEqualToString:productId] == NO) {
            continue;
        }
        
        if (expires_date) {
            expires_date = [expires_date laterDate:appReceipt.expires_date];
        }else {
            expires_date = appReceipt.expires_date;
        }
    }
    
    // 不包含过期信息表示无自动续期交易
    if (!expires_date) {
        return NO;
    }
    
    // 将当前时间统一为utc时间进行对比
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    NSString *currentDateString = [dateFormatter stringFromDate:[NSDate date]];
    NSDate *currentDate = [dateFormatter dateFromString:currentDateString];
    
    if (([expires_date timeIntervalSinceDate:iTunesResponse.receipt.request_date] > 0) && ([expires_date timeIntervalSinceDate:currentDate] > 0)) {
        // 1、对比请求时间
        // 针对SKPaymentTransactionObserver的监听，当交易信息发生更新时，苹果会自动推送当前的交易状态，
        // 缓存票据更新时的请求时间，通过与过期时间对比来确定用户的订阅是否过期
        // 此方式可以避免用户修改系统时间造成的问题，也能保证及时的更新用户订阅状况
        // 也可使用获取当前外部服务器的时间，当然需要异步操作，时间成本比较高
        
        // 2、对比系统时间
        // 防止订阅后，用户强制断网
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isValidWithPersistentProductId:(NSString *)productId
{
    return [self isValidWithPersistentProductId:productId applicationUsername:nil];
}

- (BOOL)isValidWithPersistentProductId:(NSString *)productId applicationUsername:(NSString *)applicationUsername
{
    XYiTunesResponse *iTunesResponse = [self iTunesResponseInfoWithProductId:productId applicationUsername:applicationUsername];
    if (!iTunesResponse) {
        return NO;
    }
    
    // 无票据信息直接返回NO
    if (!iTunesResponse.latest_receipt_info || iTunesResponse.latest_receipt_info.count <= 0) {
        return NO;
    }
    
    BOOL isValid = NO;
    for (XYInAppReceipt *appReceipt in iTunesResponse.latest_receipt_info) {
        
        if ([appReceipt.product_id isEqualToString:productId]) {
            isValid = YES;
            break;
        }
    }
    
    return isValid;
}


#pragma mark - XYStoreReceiptVerifier
- (void)verifyTransaction:(SKPaymentTransaction*)transaction
                  success:(void (^)(void))successBlock
                  failure:(void (^)(NSError *error))failureBlock
{
    NSString *receiptUrl = XYStoreiTunesVerifyReceiptURL;
#if DEBUG
    receiptUrl = XYStoreiTunesSandboxVerifyReceiptURL;
#endif
    __weak typeof(self) weakSelf = self;
    [[XYStore defaultStore] base64Receipt:^(NSString *base64Data) {
        [weakSelf verifyRequestData:base64Data
                                url:receiptUrl
                        transaction:transaction
                            success:successBlock
                            failure:failureBlock];
    } failure:failureBlock];
}

- (void)verifyRequestData:(NSString *)base64Data
                      url:(NSString *)url
              transaction:(SKPaymentTransaction *)transaction
                  success:(void (^)(void))successBlock
                  failure:(void (^)(NSError *error))failureBlock
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:base64Data forKey:@"receipt-data"];
    [params setValue:self.sharedSecretKey forKey:@"password"];
    
    NSError *jsonError;
    NSData *josonData = [NSJSONSerialization dataWithJSONObject:params
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:&jsonError];
    if (jsonError) {
        NSLog(@"verifyRequestData failed: error = %@", jsonError);
    }
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPBody = josonData;
    static NSString *requestMethod = @"POST";
    request.HTTPMethod = requestMethod;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!data) {
                NSError *wrapperError = [weakSelf unableVerifyReceiptError:error];
                if (failureBlock != nil) failureBlock(wrapperError);
                return;
            }
            
            NSError *jsonError;
            NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (!responseJSON) {
                NSLog(@"Failed To Parse Server Response");
                if (failureBlock != nil) failureBlock(jsonError);
            }
            
            static NSString *statusKey = @"status";
            NSInteger statusCode = [responseJSON[statusKey] integerValue];
            
            static NSInteger successCode = 0;
            static NSInteger sandboxCode = 21007;
            if (statusCode == successCode) {
                [weakSelf saveVerifiedReceipts:transaction response:responseJSON];
                if (successBlock != nil) successBlock();
            } else if (statusCode == sandboxCode) {
                [weakSelf sandboxVerify:base64Data
                            transaction:transaction
                                success:successBlock
                                failure:failureBlock];
            } else {
                NSLog(@"Verification Failed With Code %ld", (long)statusCode);
                NSError *serverError = [NSError errorWithDomain:XYStoreErrorDomain code:statusCode userInfo:nil];
                if (failureBlock != nil) failureBlock(serverError);
            }
        });
    });
}

/**
 From: https://developer.apple.com/library/ios/#technotes/tn2259/_index.html
 See also: http://stackoverflow.com/questions/9677193/ios-storekit-can-i-detect-when-im-in-the-sandbox
 Always verify your receipt first with the production URL; proceed to verify with the sandbox URL if you receive a 21007 status code. Following this approach ensures that you do not have to switch between URLs while your application is being tested or reviewed in the sandbox or is live in the App Store.
 */
- (void)sandboxVerify:(NSString *)base64Data
          transaction:(SKPaymentTransaction *)transaction
              success:(void (^)(void))successBlock
              failure:(void (^)(NSError *error))failureBlock
{
    NSLog(@"Verifying Sandbox Receipt");
    [self verifyRequestData:base64Data
                        url:XYStoreiTunesSandboxVerifyReceiptURL
                transaction:transaction
                    success:successBlock failure:failureBlock];
}

- (NSError *)unableVerifyReceiptError:(NSError *)error
{
    NSLog(@"Server Connection Failed");
    NSString *errorDesc = @"Connection to Apple failed. Check the underlying error for more info.";
    NSError *wrapperError = [NSError errorWithDomain:XYStoreErrorDomain
                                                code:XYStoreErrorCodeUnableToCompleteVerification
                                            userInfo:@{
                                                       NSUnderlyingErrorKey : error,
                                                       NSLocalizedDescriptionKey : errorDesc
                                                       }];
    return wrapperError;
}

// 存储对应的key
- (NSString *)verifiedReceiptPrefrenceKey:(NSString *)productId
                      applicationUsername:(NSString *)applicationUsername
{
    NSString *userName = applicationUsername;
    if ([applicationUsername isEqual:NULL] || [applicationUsername isKindOfClass:[NSNull class]] || !applicationUsername) {
        userName = @"";
    }
    return [NSString stringWithFormat:@"%@_%@%@", XYCachePreferenceKeyPrefix, userName, productId];
}

// 缓存票据校验结果
- (void)saveVerifiedReceipts:(SKPaymentTransaction *)transaction
                    response:(NSDictionary *)response
{
    if (!transaction) {
        return;
    }
    
    NSString *key = [self verifiedReceiptPrefrenceKey:transaction.payment.productIdentifier
                                  applicationUsername:transaction.payment.applicationUsername];
    [self.verifiedReceipts setValue:response forKey:key];
    NSString *responseJSON = [response yy_modelToJSONString];
    [[NSUserDefaults standardUserDefaults] setValue:responseJSON forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (XYiTunesResponse *)iTunesResponseInfoWithProductId:(NSString *)productId
{
    return [self iTunesResponseInfoWithProductId:productId applicationUsername:nil];
}

- (XYiTunesResponse *)iTunesResponseInfoWithProductId:(NSString *)productId
                                  applicationUsername:(NSString *)applicationUsername
{
    if (!productId) {
        return nil;
    }
    
    NSString *key = [self verifiedReceiptPrefrenceKey:productId applicationUsername:applicationUsername];
    NSDictionary *response = [self.verifiedReceipts valueForKey:key];
    if (!response) {
        id value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
        if (value) {
            value = [self.class dictionaryWithJSON:value];
        }
        response = value;
    }
    
    if (response) {
        return [XYiTunesResponse yy_modelWithDictionary:response];
    }
    
    return nil;
}

- (NSMutableDictionary *)verifiedReceipts
{
    if (!_verifiedReceipts) {
        _verifiedReceipts = [NSMutableDictionary dictionary];
    }
    
    return _verifiedReceipts;
}

+ (NSDictionary *)dictionaryWithJSON:(id)json {
    if (!json || json == (id)kCFNull) return nil;
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *)json dataUsingEncoding : NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return dic;
}


@end
