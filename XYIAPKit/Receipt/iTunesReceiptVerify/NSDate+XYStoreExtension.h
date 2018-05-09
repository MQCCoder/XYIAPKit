//
//  NSDate+XYStoreExtension.h
//  Pods
//
//  Created by qichao.ma on 2018/5/3.
//

#import <Foundation/Foundation.h>

@interface NSDate (XYStoreExtension)


/**
 时区时间转NSDate

 @param dateString "2018-03-07 06:07:36 Etc/GMT" "2018-03-23 08:30:22 America/Los_Angeles"

 */
+ (NSDate *)dateWithZoneDateString:(NSString *)dateString;


/**
  @return dateString "2018-03-07 06:07:36 Etc/GMT"
 */
+ (NSString *)GMTdateString:(NSDate *)date;

/**
 毫秒时间戳

 @param timestamp 毫秒时间戳
 */
+ (NSDate *)dateWithMSTimestamp:(NSInteger)timestamp;

@end
