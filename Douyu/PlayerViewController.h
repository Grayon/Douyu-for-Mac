//
//  PlayerViewController.h
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <mpv/client.h>
#import "DYRoomInfo.h"

@interface PlayerViewController : NSViewController

@property (assign) mpv_handle *mpv;

- (void)loadPlayerWithInfo:(DYRoomInfo *)info;
- (void)destroyPlayer;
@end
