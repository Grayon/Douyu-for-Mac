//
//  DYRoomInfo.h
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DYRoomInfo : NSObject

@property (nonatomic, copy) NSString *roomId;
@property (nonatomic, copy) NSString *roomName;
@property (nonatomic, strong) NSArray *servers;
@property (nonatomic, copy) NSString *hlsUrl;
@property (nonatomic, copy) NSString *videoUrl;
@property (nonatomic, copy) NSString *lowVideoUrl;
@property (nonatomic, copy) NSString *middleVideoUrl;
@property (nonatomic, assign) BOOL showStatus;

+ (NSString *)getRoomIdWithString:(NSString *)string;
- (BOOL)getInfoWithRoomId:(NSString *)roomId;

@end
