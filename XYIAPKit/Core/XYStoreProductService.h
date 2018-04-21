//
//  XYStoreProductService.h
//  Pods
//
//  Created by qichao.ma on 2018/4/21.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef void (^XYSKProductsRequestFailureBlock)(NSError *error);

typedef void (^XYSKProductsRequestSuccessBlock)(NSArray *products, NSArray *invalidIdentifiers);

@interface XYStoreProductService : NSObject<SKProductsRequestDelegate>

@property (nonatomic, copy) void(^addProductBlock)(SKProduct *product);

@property (nonatomic, copy) void(^removeProductRequestBlock)(XYStoreProductService *service);

- (void)requestProducts:(NSSet*)identifiers
                success:(XYSKProductsRequestSuccessBlock)successBlock
                failure:(XYSKProductsRequestFailureBlock)failureBlock;

@end
