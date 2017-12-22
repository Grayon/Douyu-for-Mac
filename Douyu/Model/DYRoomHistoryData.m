//
//  DYRoomHistoryData.m
//  Douyu
//
//  Created by Grayon on 2017/12/22.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "DYRoomHistoryData.h"

@implementation DYRoomHistoryData

+ (LKDBHelper *)getUsingLKDBHelper
{
    static LKDBHelper *helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *applicationSupportDirectory = [paths firstObject];
        NSString *dbPath = [NSString stringWithFormat:@"%@/Douyu/history.db",applicationSupportDirectory];
        helper = [[LKDBHelper alloc] initWithDBPath:dbPath];
    });
    return helper;
}

+ (void)columnAttributeWithProperty:(LKDBProperty *)property {
    property.isNotNull = YES;
}

@end
