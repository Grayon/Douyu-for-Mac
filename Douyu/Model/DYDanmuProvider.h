//
//  DYDanmuProvider.h
//  vp_tucao
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DYRoomInfo.h"

@protocol DYDanmuProviderDelegate <NSObject>

- (void)onNewMessage:(NSString *)cmContent :(NSString *)userName :(int)ftype :(int)fsize :(NSColor *)color;

@end

@interface DYDanmuProvider : NSObject

@property (nonatomic, weak) id<DYDanmuProviderDelegate> delegate;

- (void)loadWithInfo:(DYRoomInfo *)roomInfo;
- (void)disconnect;

@end
