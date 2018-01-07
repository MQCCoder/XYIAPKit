#import <UIKit/UIKit.h>

@interface XYIAPConfigItem : NSObject

@property (nonatomic, copy) NSString * commodityId;
@property (nonatomic, copy) NSString * commodityName;
@property (nonatomic, copy) NSString * currentPrice;
@property (nonatomic, assign) long long endTime;
@property (nonatomic, copy) NSString * originalPrice;
@property (nonatomic, assign) long long startTime;

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;
-(NSDictionary *)toDictionary;

@end