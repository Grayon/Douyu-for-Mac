//
//  DYRoomHistoryData.h
//  Douyu
//
//  Created by Grayon on 2017/12/22.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LKDBHelper.h>

@interface DYRoomHistoryData : NSObject

@property (nonatomic,strong) NSString *roomId;
@property (nonatomic,strong) NSString *nickname;
@property (nonatomic,strong) NSDate *lastWatchTime;

@end
