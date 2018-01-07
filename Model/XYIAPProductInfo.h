//
//  XYIAPProductInfo.h
//  GTMBase64
//
//  Created by Frenzy-Mac on 2017/10/16.
//

#import <Foundation/Foundation.h>

@interface XYIAPProductInfo : NSObject <NSCoding>

@property (nonatomic,strong) NSString *productId;
@property (nonatomic,strong) NSString *productTitle;
@property (nonatomic,strong) NSString *productDesc;
@property (nonatomic,strong) NSString *productLocalePrice;
@property (nonatomic,strong) NSString *productCurrency;
@property (nonatomic,strong) NSString *productRawPrice;
@property (nonatomic,strong) NSString *productLocaleIdentifier;

@end
