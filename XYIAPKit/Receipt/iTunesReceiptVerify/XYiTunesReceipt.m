//
//  XYiTunesReceipt.m
//  Pods
//
//  Created by qichao.ma on 2018/5/2.
//

#import "XYiTunesReceipt.h"
#import "NSDate+XYStoreExtension.h"
@implementation XYiTunesReceipt

// 返回容器类中的所需要存放的数据类型 (以 Class 或 Class Name 的形式)。
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
             @"in_app" : [XYInAppReceipt class],
             };
}

// YYModel解析
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    
    NSString *original_purchase_date = dic[@"original_purchase_date"];
    _original_purchase_date = [NSDate dateWithZoneDateString:original_purchase_date];
    
    NSString *receipt_creation_date = dic[@"receipt_creation_date"];
    _receipt_creation_date = [NSDate dateWithZoneDateString:receipt_creation_date];
    
    NSString *request_date = dic[@"request_date"];
    _request_date = [NSDate dateWithZoneDateString:request_date];
    
    return YES;
}

// YYModel解析
- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic {
    
    dic[@"original_purchase_date"] = [NSDate GMTdateString:_original_purchase_date];
    
    dic[@"receipt_creation_date"] = [NSDate GMTdateString:_receipt_creation_date];
    
    dic[@"request_date"] = [NSDate GMTdateString:_request_date];
    
    return YES;
}


@end
