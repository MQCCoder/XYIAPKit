//
//  XYReceiptRefreshService.h
//  Pods
//
//  Created by qichao.ma on 2018/4/21.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface XYReceiptRefreshService : NSObject

- (void)refreshReceiptOnSuccess:(void(^)(void))successBlock
                        failure:(void(^)(NSError *error))failureBlock;

@end
