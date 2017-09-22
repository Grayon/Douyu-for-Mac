//
//  NSString+InfoGet.m
//  
//
//  Created by LuChen on 16/2/26.
//
//

#import "NSString+InfoGet.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSString (InfoGet)

//static inline char itoh(int i) {
//    if (i > 9) return 'A' + (i - 10);
//    return '0' + i;
//}

- (NSString *)getMd5_32Bit {
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (unsigned int)self.length, digest );
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [result appendFormat:@"%02x", digest[i]];
    return result;
}

+ (NSString*)uuid{
    NSString *deviceID =[[NSUUID UUID] UUIDString];
    deviceID = [deviceID stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return deviceID;
}

+ (NSString *)timeString{
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a=[dat timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%d",(int)a];
    return timeString;
}

- (BOOL)isPureInt {
    NSScanner* scan = [NSScanner scannerWithString:self];
    int val;
    return[scan scanInt:&val] && [scan isAtEnd];
}

- (NSMutableData *)stringToHexData{
    NSData *myD = [self dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)
        
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        
        if([newHexStr length]==1)
            
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        
        else
            
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr]; 
    }
    NSString *command = [hexStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [command length]/2; i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    return commandToSend;
}

- (NSString *)componentsFirstMatchedByRegex:(NSString *)regexStr {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:self options:NSMatchingReportProgress range:NSMakeRange(0, self.length)];
    if (range.location != NSNotFound) {
        return [self substringWithRange:range];
    }
    return nil;
}

@end
