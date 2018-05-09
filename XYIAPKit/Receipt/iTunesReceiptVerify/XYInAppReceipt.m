//
//  XYInAppReceipt.m
//  Pods
//
//  Created by qichao.ma on 2018/5/3.
//

#import "XYInAppReceipt.h"
#import "NSDate+XYStoreExtension.h"

@implementation XYInAppReceipt

// YYModel解析
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    
    NSString *purchase_date = dic[@"purchase_date"];
    _purchase_date = [NSDate dateWithZoneDateString:purchase_date];
    
    NSString *original_purchase_date = dic[@"original_purchase_date"];
    _original_purchase_date = [NSDate dateWithZoneDateString:original_purchase_date];
    
    NSString *expires_date = dic[@"expires_date"];
    _expires_date = [NSDate dateWithZoneDateString:expires_date];
    
    NSString *cancellation_date = dic[@"cancellation_date"];
    _cancellation_date = [NSDate dateWithZoneDateString:cancellation_date];
    
    return YES;
}

// YYModel解析
- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic {
    
    dic[@"purchase_date"] = [NSDate GMTdateString:_purchase_date];
    
    dic[@"original_purchase_date"] = [NSDate GMTdateString:_original_purchase_date];
    
    dic[@"expires_date"] = [NSDate GMTdateString:_expires_date];
    
    dic[@"cancellation_date"] = [NSDate GMTdateString:_cancellation_date];
    
    return YES;
}

@end
