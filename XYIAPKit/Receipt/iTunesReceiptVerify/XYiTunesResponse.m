//
//  XYiTunesResponse.m
//  Pods
//
//  Created by qichao.ma on 2018/5/2.
//

#import "XYiTunesResponse.h"

@implementation XYiTunesResponse

// 返回容器类中的所需要存放的数据类型 (以 Class 或 Class Name 的形式)。
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
             @"pending_renewal_info" : [XYPendingRenewalInfo class],
             @"latest_receipt_info" : [XYInAppReceipt class],
             };
}

@end

@implementation XYPendingRenewalInfo

@end
