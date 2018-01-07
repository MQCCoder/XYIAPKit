//
//  XYIAPProductInfo.m
//  GTMBase64
//
//  Created by Frenzy-Mac on 2017/10/16.
//

#import "XYIAPProductInfo.h"

@implementation XYIAPProductInfo

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self == [super init]) {
        self.productId = [aDecoder decodeObjectForKey:@"productId"];
        self.productTitle = [aDecoder decodeObjectForKey:@"productTitle"];
        self.productDesc = [aDecoder decodeObjectForKey:@"productDesc"];
        self.productLocalePrice = [aDecoder decodeObjectForKey:@"productLocalePrice"];
        self.productCurrency = [aDecoder decodeObjectForKey:@"productCurrency"];
        self.productRawPrice = [aDecoder decodeObjectForKey:@"productRawPrice"];
        self.productLocaleIdentifier = [aDecoder decodeObjectForKey:@"productLocaleIdentifier"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.productId forKey:@"productId"];
    [aCoder encodeObject:self.productTitle forKey:@"productTitle"];
    [aCoder encodeObject:self.productDesc forKey:@"productDesc"];
    [aCoder encodeObject:self.productLocalePrice forKey:@"productLocalePrice"];
    [aCoder encodeObject:self.productCurrency forKey:@"productCurrency"];
    [aCoder encodeObject:self.productRawPrice forKey:@"productRawPrice"];
    [aCoder encodeObject:self.productLocaleIdentifier forKey:@"productLocaleIdentifier"];
}

@end
