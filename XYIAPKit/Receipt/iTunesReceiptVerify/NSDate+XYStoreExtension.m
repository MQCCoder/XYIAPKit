//
//  NSDate+XYStoreExtension.m
//  Pods
//
//  Created by qichao.ma on 2018/5/3.
//

#import "NSDate+XYStoreExtension.h"

@implementation NSDate (XYStoreExtension)

+ (NSDate *)dateWithZoneDateString:(NSString *)dateString
{
    NSArray *array = [dateString componentsSeparatedByString:@" "];
    if (array.count != 3) {
        return nil;
    }
    
    NSString *zoneName = array.lastObject;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    formatter.timeZone = [NSTimeZone timeZoneWithName:zoneName];
    NSDate *date = [formatter dateFromString:[NSString stringWithFormat:@"%@ %@", array[0], array[1]]];
    
    return date;
}

+ (NSString *)GMTdateString:(NSDate *)date
{
    if (!date) {
        return nil;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"Etc/GMT"];//东八区时间
    NSString *dateStr = [formatter stringFromDate:date];
    
    return [NSString stringWithFormat:@"%@ %@", dateStr, @"Etc/GMT"];
}

+ (NSDate *)dateWithMSTimestamp:(NSInteger)timestamp
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)(timestamp / 1000)];
    return date;
}

@end
