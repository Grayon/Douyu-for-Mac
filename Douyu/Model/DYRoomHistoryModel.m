//
//  DYRoomHistoryModel.m
//  Douyu
//
//  Created by Grayon on 2017/12/22.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "DYRoomHistoryModel.h"

@implementation DYRoomHistoryModel

+ (NSArray<DYRoomHistoryData *> *)getAll {
    return [[DYRoomHistoryData searchWithWhere:nil orderBy:@"lastWatchTime DESC" offset:0 count:0] copy];
}

+ (DYRoomHistoryData *)getRoomId:(NSString *)roomId {
    if (!roomId.length) {
        return nil;
    }
    return [DYRoomHistoryData searchSingleWithWhere:@{@"roomId":roomId} orderBy:nil];
}

+ (void)saveRoomId:(NSString *)roomId withNickname:(NSString *)nickname {
    DYRoomHistoryData *data = [self getRoomId:roomId];
    if (!data) {
        data = [[DYRoomHistoryData alloc] init];
        data.roomId = roomId;
        data.nickname = nickname;
    }
    data.lastWatchTime = [NSDate date];
    [data saveToDB];
}

@end
