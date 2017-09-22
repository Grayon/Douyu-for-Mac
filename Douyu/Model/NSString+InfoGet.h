//
//  NSString+InfoGet.h
//  
//
//  Created by LuChen on 16/2/26.
//
//

#import <Foundation/Foundation.h>

@interface NSString (InfoGet)

- (NSString *)getMd5_32Bit;//MD5加密
+ (NSString *)uuid;//获取随机UUID
+ (NSString *)timeString;//获取时间戳（秒）
- (BOOL)isPureInt;
- (NSMutableData *)stringToHexData;//转换16位的data
- (NSString *)componentsFirstMatchedByRegex:(NSString *)regexStr;

@end
