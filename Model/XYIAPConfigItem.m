//
//	XYIAPConfigItem.m
//	Model file generated using JSONExport: https://github.com/Ahmed-Ali/JSONExport



#import "XYIAPConfigItem.h"

NSString *const kXYIAPConfigItemCommodityId = @"commodityId";
NSString *const kXYIAPConfigItemCommodityName = @"commodityName";
NSString *const kXYIAPConfigItemCurrentPrice = @"currentPrice";
NSString *const kXYIAPConfigItemEndTime = @"endTime";
NSString *const kXYIAPConfigItemOriginalPrice = @"originalPrice";
NSString *const kXYIAPConfigItemStartTime = @"startTime";

@interface XYIAPConfigItem ()
@end
@implementation XYIAPConfigItem

/**
 * Instantiate the instance using the passed dictionary values to set the properties values
 */

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
	self = [super init];
	if(![dictionary[kXYIAPConfigItemCommodityId] isKindOfClass:[NSNull class]]){
		self.commodityId = dictionary[kXYIAPConfigItemCommodityId];
	}	
	if(![dictionary[kXYIAPConfigItemCommodityName] isKindOfClass:[NSNull class]]){
		self.commodityName = dictionary[kXYIAPConfigItemCommodityName];
	}	
	if(![dictionary[kXYIAPConfigItemCurrentPrice] isKindOfClass:[NSNull class]]){
		self.currentPrice = dictionary[kXYIAPConfigItemCurrentPrice];
	}	
	if(![dictionary[kXYIAPConfigItemEndTime] isKindOfClass:[NSNull class]]){
		self.endTime = [dictionary[kXYIAPConfigItemEndTime] longLongValue];
	}

	if(![dictionary[kXYIAPConfigItemOriginalPrice] isKindOfClass:[NSNull class]]){
		self.originalPrice = dictionary[kXYIAPConfigItemOriginalPrice];
	}	
	if(![dictionary[kXYIAPConfigItemStartTime] isKindOfClass:[NSNull class]]){
		self.startTime = [dictionary[kXYIAPConfigItemStartTime] longLongValue];
	}

	return self;
}


/**
 * Returns all the available property values in the form of NSDictionary object where the key is the approperiate json key and the value is the value of the corresponding property
 */
-(NSDictionary *)toDictionary
{
	NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
	if(self.commodityId != nil){
		dictionary[kXYIAPConfigItemCommodityId] = self.commodityId;
	}
	if(self.commodityName != nil){
		dictionary[kXYIAPConfigItemCommodityName] = self.commodityName;
	}
	if(self.currentPrice != nil){
		dictionary[kXYIAPConfigItemCurrentPrice] = self.currentPrice;
	}
	dictionary[kXYIAPConfigItemEndTime] = @(self.endTime);
	if(self.originalPrice != nil){
		dictionary[kXYIAPConfigItemOriginalPrice] = self.originalPrice;
	}
	dictionary[kXYIAPConfigItemStartTime] = @(self.startTime);
	return dictionary;

}

/**
 * Implementation of NSCoding encoding method
 */
/**
 * Returns all the available property values in the form of NSDictionary object where the key is the approperiate json key and the value is the value of the corresponding property
 */
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	if(self.commodityId != nil){
		[aCoder encodeObject:self.commodityId forKey:kXYIAPConfigItemCommodityId];
	}
	if(self.commodityName != nil){
		[aCoder encodeObject:self.commodityName forKey:kXYIAPConfigItemCommodityName];
	}
	if(self.currentPrice != nil){
		[aCoder encodeObject:self.currentPrice forKey:kXYIAPConfigItemCurrentPrice];
	}
	[aCoder encodeObject:@(self.endTime) forKey:kXYIAPConfigItemEndTime];	if(self.originalPrice != nil){
		[aCoder encodeObject:self.originalPrice forKey:kXYIAPConfigItemOriginalPrice];
	}
	[aCoder encodeObject:@(self.startTime) forKey:kXYIAPConfigItemStartTime];
}

/**
 * Implementation of NSCoding initWithCoder: method
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	self.commodityId = [aDecoder decodeObjectForKey:kXYIAPConfigItemCommodityId];
	self.commodityName = [aDecoder decodeObjectForKey:kXYIAPConfigItemCommodityName];
	self.currentPrice = [aDecoder decodeObjectForKey:kXYIAPConfigItemCurrentPrice];
	self.endTime = [[aDecoder decodeObjectForKey:kXYIAPConfigItemEndTime] integerValue];
	self.originalPrice = [aDecoder decodeObjectForKey:kXYIAPConfigItemOriginalPrice];
	self.startTime = [[aDecoder decodeObjectForKey:kXYIAPConfigItemStartTime] integerValue];
	return self;

}

/**
 * Implementation of NSCopying copyWithZone: method
 */
- (instancetype)copyWithZone:(NSZone *)zone
{
	XYIAPConfigItem *copy = [XYIAPConfigItem new];

	copy.commodityId = [self.commodityId copyWithZone:zone];
	copy.commodityName = [self.commodityName copyWithZone:zone];
	copy.currentPrice = [self.currentPrice copyWithZone:zone];
	copy.endTime = self.endTime;
	copy.originalPrice = [self.originalPrice copyWithZone:zone];
	copy.startTime = self.startTime;

	return copy;
}
@end