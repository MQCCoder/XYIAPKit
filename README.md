# XYIAPKit

[![CI Status](http://img.shields.io/travis/1073605877/XYIAPKit.svg?style=flat)](https://travis-ci.org/1073605877/XYIAPKit)
[![Version](https://img.shields.io/cocoapods/v/XYIAPKit.svg?style=flat)](http://cocoapods.org/pods/XYIAPKit)
[![License](https://img.shields.io/cocoapods/l/XYIAPKit.svg?style=flat)](http://cocoapods.org/pods/XYIAPKit)
[![Platform](https://img.shields.io/cocoapods/p/XYIAPKit.svg?style=flat)](http://cocoapods.org/pods/XYIAPKit)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

XYIAPKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'XYIAPKit'
```

## 功能
1、内购的基本功能，产品列表查询、添加购买、恢复购买

2、票据校验、自动续费订阅过期检测

3、交易记录保存

## 使用方法

1、查询在线商品
```
/**
 请求在线商品，并存储于内存中

 @param identifiers 产品id
 */
- (void)requestProducts:(NSSet*)identifiers
                success:(void (^)(NSArray *products, NSArray *invalidProductIdentifiers))successBlock
                failure:(void (^)(NSError *error))failureBlock;

#########################################################################################################

	NSSet *set = [[NSSet alloc] initWithArray:@[@"1", @"2", @"3", @"4", @"5", @"6"]];
    [[XYStore defaultStore] requestProducts:set
                                    success:^(NSArray *products, NSArray *invalidProductIdentifiers)
     {

     } failure:^(NSError *error) {

     }];
```

2、添加购买

```
    [[XYStore defaultStore] addPayment:productId
                               success:^(SKPaymentTransaction *transaction)
    {

        
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {

    }];
```

3、恢复内购
```
[[XYStore defaultStore] restoreTransactionsOnSuccess:^(NSArray *transactions) {
        
        NSLog(@"restore === %@", transactions);
    } failure:^(NSError *error) {
        NSLog(@"restore error === %@", error);
    }];
```

4、添加票据校验

	1）、外部票据校验（可以通过信任的服务器进行校验）
	创建校验对象(建议创建单例对象，以便监听)，遵守XYStoreReceiptVerifier协议

```
- (void)verifyTransaction:(SKPaymentTransaction *)transaction
                  success:(void (^)(void))successBlock
                  failure:(void (^)(NSError *))failureBlock
{
    __weak typeof(self) weakSelf = self;
    [[XYStore defaultStore] base64Receipt:^(NSString *base64Data) {
        
        [[XYStore defaultStore] fetchProduct:transaction.payment.productIdentifier
                                     success:^(SKProduct *product)
         {
         	//外部校验请求
             [weakSelf callBackApple:product
                         receiptData:base64Data
                             success:successBlock
                             failure:failureBlock];
             
         } failure:failureBlock];
        
    } failure:failureBlock];
}
```

	在`- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions `中注册票据校验
```
	// 在此设置内购的票据校验，防止掉单问题的发生
    [[XYStore defaultStore] registerReceiptVerifier:[XYAppReceiptVerifier shareInstance]];
```

	2)、APP内部校验

	podfile中添加`pod 'XYIAPKit/iTunesReceiptVerify', '~> 0.8.0'`
	引入票据校验的sdk

	在`- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions `中注册票据校验

```
	// 在此设置内购的票据校验，防止掉单问题的发生
    [[XYStore defaultStore] registerReceiptVerifier:[XYStoreiTunesReceiptVerifier shareInstance]];
```

	XYStoreiTunesReceiptVerifier中提供对自动续期产品的订阅过期的判断
```
	/**
 @ 适用自动续期订阅
 
 判断是否已订阅
 若果是非自动续费型商品，直接返回NO

 @param productId 自动续期订阅产品id
 @return YES：  NO：未订阅或者订阅过期
 */
- (BOOL)isSubscribedWithAutoRenewProduct:(NSString *)productId;
```
	也提供 针对持续有效的产品，Apple返回的票据记录中会一直保留其票据信息，可以通过票据记录判断是否有效
```
/**
 针对持续有效的产品，Apple返回的票据记录中会一直保留其票据信息，可以通过票据记录判断是否有效
 支持：1、非续期订阅 2、非消耗型项目
 
 注：消耗型项目一旦完成，不会长期保留在票据信息中
 
 @param productId 产品id
 @return YES：消费有效 NO：无效
 */
- (BOOL)isValidWithPersistentProductId:(NSString *)productId;
```

5、添加交易记录存储
	1）、存储在NSUserDefaults
	podfile中添加`pod 'XYIAPKit/UserDefaultPersistence', :'~> 0.8.0'`

	在`- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions `中注册票据校验

```
	// 在此设置内购的票据校验，防止掉单问题的发生
    [[XYStore defaultStore] registerTransactionPersistor:[XYStoreUserDefaultsPersistence shareInstance]];

```

	2)、存储于Keychain中
		podfile中添加`pod 'XYIAPKit/KeychainPersistence', '~> 0.8.0'`

	在`- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions `中注册票据校验

```
	// 在此设置内购的票据校验，防止掉单问题的发生
    [[XYStore defaultStore] registerTransactionPersistor:[XYStoreKeychainPersistence shareInstance]];

```

## Author

1073605877, qichao.ma@quvideo.com

## License

XYIAPKit is available under the MIT license. See the LICENSE file for more info.
