//
//  XYStoreAppReceiptVerifier.h
//  Pods
//
//  Created by qichao.ma on 2018/4/19.
//

#import <Foundation/Foundation.h>
#import "XYStore.h"

/**
 票据校验
 */

@interface XYStoreAppReceiptVerifier : NSObject<XYStoreReceiptVerifier>

@property (nonatomic, strong) NSString *bundleIdentifier;

/**
 The value that will be used to validate the bundle version included in the app receipt. Given that it is possible to modify the app bundle in jailbroken devices, setting this value from a hardcoded string might provide better protection.
 @return The given value, or the app's bundle version by defult.
 */
@property (nonatomic, strong) NSString *bundleVersion;

/**
 Verifies the app receipt by checking the integrity of the receipt, comparing its bundle identifier and bundle version to the values returned by the corresponding properties and verifying the receipt hash.
 @return YES if the receipt is verified, NO otherwise.
 @discussion If validation fails in iOS, Apple recommends to refresh the receipt and try again.
 */
- (BOOL)verifyAppReceipt;


@end
