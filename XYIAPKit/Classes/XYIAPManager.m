//
//  XYIAPManager.m
//  Pods
//
//  Created by mqc on 2018/1/8.
//

#import "XYIAPManager.h"
#import "NSUserDefaults+XYSafeAccess.h"

#define XY_PRE_IAP_PRODUCT_INFO         @"xy_pre_iap_product_info"

@interface XYIAPManager()<SKProductsRequestDelegate>

@property (nonatomic, strong) NSHashTable *observers;

@property (nonatomic, copy) XYIAPResponseBlock responseBlock;

@property (nonatomic, strong) SKProductsResponse *productsResponse;

@end

@implementation XYIAPManager

+ (instancetype)shareInstance
{
    static XYIAPManager *shareInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[XYIAPManager alloc] init];
    });
    
    return shareInstance;
}

#pragma mark - Observer

- (void)registerObserver:(id)observer {
    
    if (![self.observers containsObject:observer]) {
        [self.observers addObject:observer];
    }
}

- (void)unregisterObserver:(id)observer {
    [self.observers removeObject:observer];
}

#pragma mark - Notify

- (void)notifyWithIdentifier:(NSString *)identifier result:(BOOL)isValid
{
    for (id observer in self.observers) {
        if ([observer respondsToSelector:@selector(observeIAPWithIdentifier:result:)]) {
            [observer observeIAPWithIdentifier:identifier result:isValid];
        }
    }
}


- (void)requestProductsWithProductIdentifiers:(NSArray *)productIdentifiers block:(XYIAPResponseBlock)block
{
    if (!productIdentifiers || [productIdentifiers count] == 0) {
        return;
    }
    
    self.responseBlock = block;
    if ([SKPaymentQueue canMakePayments]) {
        
        NSSet * set = [NSSet setWithArray:productIdentifiers];
        SKProductsRequest * request = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
        request.delegate = self;
        [request start];
        
    }else {
        NSLog(@"失败，用户禁止应用内付费购买.");
        if (block) {
            block(XYIAPRequestResultNoPermission);
        }
    }
}

#pragma mark - SKProductsRequestDelegate
// 以上查询的回调函数
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    if (!response.products || response.products == 0) {
        NSLog(@"无法获取产品信息");
        if (self.responseBlock) {
            self.responseBlock(XYIAPRequestResultFailed);
        }
        return;
    }
    
    self.productsResponse = response;
    // 存储查询的商品信息
    [self saveProductsInfo:response];
    
    if (self.responseBlock) {
        self.responseBlock(XYIAPRequestResultSuccess);
    }
}

#pragma mark - 存储产品信息
- (void)saveProductsInfo:(SKProductsResponse *)response
{
    for (SKProduct *product in response.products) {
        XYIAPProductInfo *info = [self productInfoWithSKProduct:product];
        
        NSString *key = [self productPreKey:product.productIdentifier];
        [NSUserDefaults xy_setArcObject:info forKey:key];
    }
}

#pragma mark - Tool

- (BOOL)isValidProduct:(NSString *)identifier
{
    NSArray<SKProduct *> *products = [self validProducts];
    
    BOOL isValid = NO;
    for (SKProduct *product in products) {
        if ([identifier isEqualToString:product.productIdentifier]) {
            isValid = YES;
            break;
        }
    }
    
    return isValid;
}

- (NSArray<SKProduct *> *)validProducts
{
    SKProductsResponse *response = self.productsResponse;
    
    NSMutableArray *validProducts = [NSMutableArray array];
    for (SKProduct *product in response.products) {
        if ([response.invalidProductIdentifiers containsObject:product.productIdentifier] == NO) {
            [validProducts addObject:product];
        }
    }
    
    return validProducts;
}

- (SKProduct *)skProductWithIdentifier:(NSString *)identifier
{
    SKProductsResponse *response = self.productsResponse;
    
    SKProduct *skProduct;
    for (SKProduct *product in response.products) {
        if ([product.productIdentifier isEqualToString:identifier]) {
            skProduct = product;
            break;
        }
    }
    
    return skProduct;
}

- (NSString *)productPreKey:(NSString *)identifier
{
    return [NSString stringWithFormat:@"%@_%@", XY_PRE_IAP_PRODUCT_INFO, identifier];
}

- (XYIAPProductInfo *)productInfoWithSKProduct:(SKProduct *)skProduct
{
    if (skProduct) {
        XYIAPProductInfo *productInfo = [[XYIAPProductInfo alloc] init];
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehaviorDefault];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:skProduct.priceLocale];
        productInfo.productLocalePrice = [numberFormatter stringFromNumber:skProduct.price];//$0.99
        productInfo.productTitle = skProduct.localizedTitle;
        productInfo.productDesc  = skProduct.localizedDescription;
        productInfo.productId = skProduct.productIdentifier;
        productInfo.productRawPrice = [skProduct.price stringValue];//0.99
        productInfo.productCurrency = [numberFormatter currencyCode];//USD
        productInfo.productLocaleIdentifier = skProduct.priceLocale.localeIdentifier;
        
        return productInfo;
    }
    
    return nil;
}

- (XYIAPProductInfo *)productInfoWithIdentifier:(NSString *)identifier
{
    XYIAPProductInfo *info;
    SKProduct *product = [self skProductWithIdentifier:identifier];
    if (product) {
        info =  [self productInfoWithSKProduct:product];
    }else {
        info = [NSUserDefaults xy_arcObjectForKey:[self productPreKey:identifier]];
    }
    
    return info;
}


#pragma mark - lazy load

- (NSHashTable *)observers
{
    if (!_observers) {
        _observers = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
    }
    
    return _observers;
}

@end
