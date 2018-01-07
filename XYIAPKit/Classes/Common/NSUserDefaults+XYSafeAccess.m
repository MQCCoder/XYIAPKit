//
//  NSUserDefaults+XYSafeAccess.m
//  Pods
//
//  Created by qichao.ma on 2017/12/22.
//

#import "NSUserDefaults+XYSafeAccess.h"

@implementation NSUserDefaults (XYSafeAccess)

#pragma mark - READ ARCHIVE FOR STANDARD

+ (id)xy_arcObjectForKey:(NSString *)defaultName {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:defaultName]];
}

#pragma mark - WRITE ARCHIVE FOR STANDARD

+ (void)xy_setArcObject:(id)value forKey:(NSString *)defaultName {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:value] forKey:defaultName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
