//
//  XYStoreiTunesReceiptVerifier.h
//  Pods
//
//  Created by qichao.ma on 2018/5/2.
//

#import <Foundation/Foundation.h>
#import "XYStore.h"

@interface XYStoreiTunesReceiptVerifier : NSObject<XYStoreReceiptVerifier>

/**
 App 专用共享密钥
 
 App 专用共享密钥是用于接收此 App 自动续订订阅收据的唯一代码。
 如果您需要将此 App 转让给其他开发人员，或者需要将主共享密钥设置为专用，可能需要使用 App 专用共享密钥。
 */
@property (nonatomic, copy) NSString *sharedSecretKey;

+ (instancetype)shareInstance;


/**
 @ 适用自动续期订阅
 
 判断是否已订阅
 若果是非自动续费型商品，直接返回NO

 @param productId 自动续期订阅产品id
 @return YES：  NO：未订阅或者订阅过期
 */
- (BOOL)isSubscribedWithAutoRenewProduct:(NSString *)productId;

/**
 @ 适用自动续期订阅
 
 @param applicationUsername
 An opaque identifier for the user’s account on your system.
 Use this property to help the store detect irregular activity. For example, in a game, it would be unusual for dozens of different iTunes Store accounts to make purchases on behalf of the same in-game character.
 The recommended implementation is to use a one-way hash of the user’s account name to calculate the value for this property.
 */
- (BOOL)isSubscribedWithAutoRenewProduct:(NSString *)productId applicationUsername:(NSString *)applicationUsername;

/**
 针对持续有效的产品，Apple返回的票据记录中会一直保留其票据信息，可以通过票据记录判断是否有效
 支持：1、非续期订阅 2、非消耗型项目
 
 注：消耗型项目一旦完成，不会长期保留在票据信息中
 
 @param productId 产品id
 @return YES：消费有效 NO：无效
 */
- (BOOL)isValidWithPersistentProductId:(NSString *)productId;

- (BOOL)isValidWithPersistentProductId:(NSString *)productId applicationUsername:(NSString *)applicationUsername;


@end
