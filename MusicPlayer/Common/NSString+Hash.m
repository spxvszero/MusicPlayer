//
//  NSString+Hash.m
//

#import "NSString+Hash.h"
#import <CommonCrypto/CommonDigest.h>




@implementation NSString (Hash)

- (NSString *)musicHashString
{
    UInt8 buf[4096];
    CFIndex usedBytes = 0;
    
    CFStringRef str = (__bridge CFStringRef)self;
    
    CFStringGetBytes(str,
                     CFRangeMake(0, CFStringGetLength(str)),
                     kCFStringEncodingUTF8,
                     '?',
                     false,
                     buf,
                     4096,
                     &usedBytes);
    
    CC_SHA1_CTX hashObject;
    CC_SHA1_Init(&hashObject);
    
    CC_SHA1_Update(&hashObject,
                   (const void *)buf,
                   (CC_LONG)usedBytes);
    
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_Final(digest, &hashObject);
    
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    
    return (__bridge NSString *)CFStringCreateWithCString(kCFAllocatorDefault,
                                     (const char *)hash,
                                     kCFStringEncodingUTF8);
}

- (NSString *)sha1
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

@end
