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
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSString *videoUrl;
@property (nonatomic, assign) BOOL showStatus;

@property (nonatomic, copy) NSString *did;
@property (nonatomic, copy) NSString *roomJS;

- (NSString *)getRoomIdWithString:(NSString *)string;
- (BOOL)getInfoWithRoomId:(NSString *)roomId rate:(int)rate;

@end
