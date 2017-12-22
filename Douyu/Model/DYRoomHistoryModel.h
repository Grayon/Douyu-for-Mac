//
//  DYRoomHistoryModel.h
//  Douyu
//
//  Created by Grayon on 2017/12/22.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DYRoomHistoryData.h"

@interface DYRoomHistoryModel : NSObject

+ (NSArray<DYRoomHistoryData *> *)getAll;
+ (DYRoomHistoryData *)getRoomId:(NSString *)roomId;
+ (void)saveRoomId:(NSString *)roomId withNickname:(NSString *)nickname;

@end
