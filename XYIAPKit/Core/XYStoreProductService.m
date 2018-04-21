//
//  XYStoreProductService.m
//  Pods
//
//  Created by qichao.ma on 2018/4/21.
//

#import "XYStoreProductService.h"
#import "XYStore.h"

@interface XYStoreProductService()

@property (nonatomic, copy) XYSKProductsRequestSuccessBlock successBlock;

@property (nonatomic, copy) XYSKProductsRequestFailureBlock failureBlock;

@end

@implementation XYStoreProductService

- (void)requestProducts:(NSSet*)identifiers
                success:(XYSKProductsRequestSuccessBlock)successBlock
                failure:(XYSKProductsRequestFailureBlock)failureBlock
{
    _successBlock = successBlock;
    _failureBlock = failureBlock;
    
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"products request received response");
    NSArray *products = [NSArray arrayWithArray:response.products];
    NSArray *invalidProductIdentifiers = [NSArray arrayWithArray:response.invalidProductIdentifiers];
    
    for (SKProduct *product in products)
    {
        NSLog(@"received product with id %@", product.productIdentifier);
        if (_addProductBlock) {
            _addProductBlock(product);
        }
    }
    
    [invalidProductIdentifiers enumerateObjectsUsingBlock:^(NSString *invalid, NSUInteger idx, BOOL *stop) {
        NSLog(@"invalid product with id %@", invalid);
    }];
    
    if (self.successBlock)
    {
        self.successBlock(products, invalidProductIdentifiers);
    }
}

- (void)requestDidFinish:(SKRequest *)request
{
    if (_removeProductRequestBlock) {
        _removeProductRequestBlock(self);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"products request failed with error %@", error.debugDescription);
    if (self.failureBlock)
    {
        self.failureBlock(error);
    }

    if (_removeProductRequestBlock) {
        _removeProductRequestBlock(self);
    }
}


@end


