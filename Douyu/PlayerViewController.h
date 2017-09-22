//
//  PlayerViewController.h
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DYRoomInfo.h"

@interface PlayerViewController : NSViewController

- (void)loadPlayerWithInfo:(DYRoomInfo *)info;
- (void)destroyPlayer;
@end
