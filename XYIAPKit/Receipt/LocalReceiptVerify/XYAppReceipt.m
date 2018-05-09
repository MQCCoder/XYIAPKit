//
//  XYAppReceipt.m
//  Pods
//
//  Created by qichao.ma on 2018/4/19.
//

#import "XYAppReceipt.h"
#import <UIKit/UIKit.h>
#import <openssl/pkcs7.h>
#import <openssl/objects.h>
#import <openssl/sha.h>
#import <openssl/x509.h>

// From https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1
NSInteger const XYAppReceiptASN1TypeBundleIdentifier = 2;
NSInteger const XYAppReceiptASN1TypeAppVersion = 3;
NSInteger const XYAppReceiptASN1TypeOpaqueValue = 4;
NSInteger const XYAppReceiptASN1TypeHash = 5;
NSInteger const XYAppReceiptASN1TypeInAppPurchaseReceipt = 17;
NSInteger const XYAppReceiptASN1TypeOriginalAppVersion = 19;
NSInteger const XYAppReceiptASN1TypeExpirationDate = 21;

NSInteger const XYAppReceiptASN1TypeQuantity = 1701;
NSInteger const XYAppReceiptASN1TypeProductIdentifier = 1702;
NSInteger const XYAppReceiptASN1TypeTransactionIdentifier = 1703;
NSInteger const XYAppReceiptASN1TypePurchaseDate = 1704;
NSInteger const XYAppReceiptASN1TypeOriginalTransactionIdentifier = 1705;
NSInteger const XYAppReceiptASN1TypeOriginalPurchaseDate = 1706;
NSInteger const XYAppReceiptASN1TypeSubscriptionExpirationDate = 1708;
NSInteger const XYAppReceiptASN1TypeWebOrderLineItemID = 1711;
NSInteger const XYAppReceiptASN1TypeCancellationDate = 1712;

#pragma mark - ANS1

static int XYASN1ReadInteger(const uint8_t **pp, long omax)
{
    int tag, asn1Class;
    long length;
    int value = 0;
    ASN1_get_object(pp, &length, &tag, &asn1Class, omax);
    if (tag == V_ASN1_INTEGER)
    {
        for (int i = 0; i < length; i++)
        {
            value = value * 0x100 + (*pp)[i];
        }
    }
    *pp += length;
    return value;
}

static NSData* XYASN1ReadOctectString(const uint8_t **pp, long omax)
{
    int tag, asn1Class;
    long length;
    NSData *data = nil;
    ASN1_get_object(pp, &length, &tag, &asn1Class, omax);
    if (tag == V_ASN1_OCTET_STRING)
    {
        data = [NSData dataWithBytes:*pp length:length];
    }
    *pp += length;
    return data;
}

static NSString* XYASN1ReadString(const uint8_t **pp, long omax, int expectedTag, NSStringEncoding encoding)
{
    int tag, asn1Class;
    long length;
    NSString *value = nil;
    ASN1_get_object(pp, &length, &tag, &asn1Class, omax);
    if (tag == expectedTag)
    {
        value = [[NSString alloc] initWithBytes:*pp length:length encoding:encoding];
    }
    *pp += length;
    return value;
}

static NSString* XYASN1ReadUTF8String(const uint8_t **pp, long omax)
{
    return XYASN1ReadString(pp, omax, V_ASN1_UTF8STRING, NSUTF8StringEncoding);
}

static NSString* XYASN1ReadIA5SString(const uint8_t **pp, long omax)
{
    return XYASN1ReadString(pp, omax, V_ASN1_IA5STRING, NSASCIIStringEncoding);
}

static NSURL *_appleRootCertificateURL = nil;

@implementation XYAppReceipt

- (instancetype)initWithASN1Data:(NSData*)asn1Data
{
    if (self = [super init])
    {
        NSMutableArray *purchases = [NSMutableArray array];
        // Explicit casting to avoid errors when compiling as Objective-C++
        [XYAppReceipt enumerateASN1Attributes:(const uint8_t*)asn1Data.bytes
                                       length:asn1Data.length
                                   usingBlock:^(NSData *data, int type)
         {
            const uint8_t *s = (const uint8_t*)data.bytes;
            const NSUInteger length = data.length;
            switch (type)
            {
                case XYAppReceiptASN1TypeBundleIdentifier:
                    _bundleIdentifierData = data;
                    _bundleIdentifier = XYASN1ReadUTF8String(&s, length);
                    break;
                case XYAppReceiptASN1TypeAppVersion:
                    _appVersion = XYASN1ReadUTF8String(&s, length);
                    break;
                case XYAppReceiptASN1TypeOpaqueValue:
                    _opaqueValue = data;
                    break;
                case XYAppReceiptASN1TypeHash:
                    _receiptHash = data;
                    break;
                case XYAppReceiptASN1TypeInAppPurchaseReceipt:
                {
                    XYAppReceiptIAP *purchase = [[XYAppReceiptIAP alloc] initWithASN1Data:data];
                    [purchases addObject:purchase];
                    break;
                }
                case XYAppReceiptASN1TypeOriginalAppVersion:
                    _originalAppVersion = XYASN1ReadUTF8String(&s, length);
                    break;
                case XYAppReceiptASN1TypeExpirationDate:
                {
                    NSString *string = XYASN1ReadIA5SString(&s, length);
                    _expirationDate = [XYAppReceipt formatRFC3339String:string];
                    break;
                }
            }
        }];
        _inAppPurchases = purchases;
    }
    return self;
}

- (BOOL)containsInAppPurchaseOfProductIdentifier:(NSString*)productIdentifier
{
    for (XYAppReceiptIAP *purchase in _inAppPurchases)
    {
        if ([purchase.productIdentifier isEqualToString:productIdentifier])
        {
            return YES;
        }
    }
    return NO;
}

-(BOOL)containsActiveAutoRenewableSubscriptionOfProductIdentifier:(NSString *)productIdentifier forDate:(NSDate *)date
{
    XYAppReceiptIAP *lastTransaction = nil;
    
    for (XYAppReceiptIAP *iap in self.inAppPurchases)
    {
        if (![iap.productIdentifier isEqualToString:productIdentifier]) continue;
        
        if (!lastTransaction || [iap.subscriptionExpirationDate compare:lastTransaction.subscriptionExpirationDate] == NSOrderedDescending)
        {
            lastTransaction = iap;
        }
    }
    
    return [lastTransaction isActiveAutoRenewableSubscriptionForDate:date];
}

- (BOOL)verifyReceiptHash
{
    // TODO: Getting the uuid in Mac is different. See: https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW5
    NSUUID *uuid = [UIDevice currentDevice].identifierForVendor;
    unsigned char uuidBytes[16];
    [uuid getUUIDBytes:uuidBytes];
    
    // Order taken from: https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW5
    NSMutableData *data = [NSMutableData data];
    [data appendBytes:uuidBytes length:sizeof(uuidBytes)];
    [data appendData:self.opaqueValue];
    [data appendData:self.bundleIdentifierData];
    
    NSMutableData *expectedHash = [NSMutableData dataWithLength:SHA_DIGEST_LENGTH];
    SHA1((const uint8_t*)data.bytes, data.length, (uint8_t*)expectedHash.mutableBytes); // Explicit casting to avoid errors when compiling as Objective-C++
    
    return [expectedHash isEqualToData:self.receiptHash];
}

+ (XYAppReceipt*)bundleReceipt
{
    NSURL *URL = [NSBundle mainBundle].appStoreReceiptURL;
    NSString *path = URL.path;
    const BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil];
    if (!exists) return nil;
    NSData *data = [XYAppReceipt dataFromPCKS7Path:path];
    if (!data) return nil;
    
    XYAppReceipt *receipt = [[XYAppReceipt alloc] initWithASN1Data:data];
    return receipt;
}

+ (void)setAppleRootCertificateURL:(NSURL*)url
{
    _appleRootCertificateURL = url;
}

#pragma mark - Utils

+ (NSData*)dataFromPCKS7Path:(NSString*)path
{
    const char *cpath = path.stringByStandardizingPath.fileSystemRepresentation;
    FILE *fp = fopen(cpath, "rb");
    if (!fp) return nil;
    
    PKCS7 *p7 = d2i_PKCS7_fp(fp, NULL);
    fclose(fp);
    
    if (!p7) return nil;
    
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"XYIAPKit" withExtension:@"bundle"]];
    NSData *data;
    NSURL *certificateURL = _appleRootCertificateURL ? : [bundle URLForResource:@"AppleIncRootCertificate" withExtension:@"cer"];
    
    NSData *certificateData = [NSData dataWithContentsOfURL:certificateURL];
    if (!certificateData || [self verifyPCKS7:p7 withCertificateData:certificateData])
    {
        struct pkcs7_st *contents = p7->d.sign->contents;
        if (PKCS7_type_is_data(contents))
        {
            ASN1_OCTET_STRING *octets = contents->d.data;
            data = [NSData dataWithBytes:octets->data length:octets->length];
        }
    }
    PKCS7_free(p7);
    return data;
}

+ (BOOL)verifyPCKS7:(PKCS7*)container withCertificateData:(NSData*)certificateData
{ // Based on: https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW17
    static int verified = 1;
    int result = 0;
    OpenSSL_add_all_digests(); // Required for PKCS7_verify to work
    X509_STORE *store = X509_STORE_new();
    if (store)
    {
        const uint8_t *certificateBytes = (uint8_t *)(certificateData.bytes);
        X509 *certificate = d2i_X509(NULL, &certificateBytes, (long)certificateData.length);
        if (certificate)
        {
            X509_STORE_add_cert(store, certificate);
            
            BIO *payload = BIO_new(BIO_s_mem());
            result = PKCS7_verify(container, NULL, store, NULL, payload, 0);
            BIO_free(payload);
            
            X509_free(certificate);
        }
    }
    X509_STORE_free(store);
    EVP_cleanup(); // Balances OpenSSL_add_all_digests (), perhttp://www.openssl.org/docs/crypto/OpenSSL_add_all_algorithms.html
    
    return result == verified;
}

/*
 Based on https://github.com/rmaddy/VerifyStoreReceiptiOS
 */
+ (void)enumerateASN1Attributes:(const uint8_t*)p length:(long)tlength usingBlock:(void (^)(NSData *data, int type))block
{
    int type, tag;
    long length;
    
    const uint8_t *end = p + tlength;
    
    ASN1_get_object(&p, &length, &type, &tag, end - p);
    if (type != V_ASN1_SET) return;
    
    while (p < end)
    {
        ASN1_get_object(&p, &length, &type, &tag, end - p);
        if (type != V_ASN1_SEQUENCE) break;
        
        const uint8_t *sequenceEnd = p + length;
        
        const int attributeType = XYASN1ReadInteger(&p, sequenceEnd - p);
        XYASN1ReadInteger(&p, sequenceEnd - p); // Consume attribute version
        
        NSData *data = XYASN1ReadOctectString(&p, sequenceEnd - p);
        if (data)
        {
            block(data, attributeType);
        }
        
        while (p < sequenceEnd)
        { // Skip remaining fields
            ASN1_get_object(&p, &length, &type, &tag, sequenceEnd - p);
            p += length;
        }
    }
}

+ (NSDate*)formatRFC3339String:(NSString*)string
{
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    NSDate *date = [formatter dateFromString:string];
    return date;
}

@end

@implementation XYAppReceiptIAP

- (instancetype)initWithASN1Data:(NSData*)asn1Data
{
    if (self = [super init])
    {
        // Explicit casting to avoid errors when compiling as Objective-C++
        [XYAppReceipt enumerateASN1Attributes:(const uint8_t*)asn1Data.bytes length:asn1Data.length usingBlock:^(NSData *data, int type) {
            const uint8_t *p = (const uint8_t*)data.bytes;
            const NSUInteger length = data.length;
            switch (type)
            {
                case XYAppReceiptASN1TypeQuantity:
                    _quantity = XYASN1ReadInteger(&p, length);
                    break;
                case XYAppReceiptASN1TypeProductIdentifier:
                    _productIdentifier = XYASN1ReadUTF8String(&p, length);
                    break;
                case XYAppReceiptASN1TypeTransactionIdentifier:
                    _transactionIdentifier = XYASN1ReadUTF8String(&p, length);
                    break;
                case XYAppReceiptASN1TypePurchaseDate:
                {
                    NSString *string = XYASN1ReadIA5SString(&p, length);
                    _purchaseDate = [XYAppReceipt formatRFC3339String:string];
                    break;
                }
                case XYAppReceiptASN1TypeOriginalTransactionIdentifier:
                    _originalTransactionIdentifier = XYASN1ReadUTF8String(&p, length);
                    break;
                case XYAppReceiptASN1TypeOriginalPurchaseDate:
                {
                    NSString *string = XYASN1ReadIA5SString(&p, length);
                    _originalPurchaseDate = [XYAppReceipt formatRFC3339String:string];
                    break;
                }
                case XYAppReceiptASN1TypeSubscriptionExpirationDate:
                {
                    NSString *string = XYASN1ReadIA5SString(&p, length);
                    _subscriptionExpirationDate = [XYAppReceipt formatRFC3339String:string];
                    break;
                }
                case XYAppReceiptASN1TypeWebOrderLineItemID:
                    _webOrderLineItemID = XYASN1ReadInteger(&p, length);
                    break;
                case XYAppReceiptASN1TypeCancellationDate:
                {
                    NSString *string = XYASN1ReadIA5SString(&p, length);
                    _cancellationDate = [XYAppReceipt formatRFC3339String:string];
                    break;
                }
            }
        }];
    }
    return self;
}

- (BOOL)isActiveAutoRenewableSubscriptionForDate:(NSDate*)date
{
    NSAssert(self.subscriptionExpirationDate != nil, @"The product %@ is not an auto-renewable subscription.", self.productIdentifier);
    
    if (self.cancellationDate) return NO;
    
    return [self.purchaseDate compare:date] != NSOrderedDescending && [date compare:self.subscriptionExpirationDate] != NSOrderedDescending;
}


@end
