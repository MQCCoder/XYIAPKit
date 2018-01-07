//
//  NSUserDefaults+XYSafeAccess.h
//  Pods
//
//  Created by qichao.ma on 2017/12/22.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (XYSafeAccess)

+ (id)xy_arcObjectForKey:(NSString *)defaultName;

+ (void)xy_setArcObject:(id)value forKey:(NSString *)defaultName;

@end
