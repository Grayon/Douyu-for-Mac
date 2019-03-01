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
#import "BarrageRenderer.h"
#import "MpvClientOGLView.h"

@interface PlayerViewController : NSViewController

@property mpv_handle *mpv;
@property (weak, nonatomic) IBOutlet MpvClientOGLView *glView;
@property (strong, nonatomic) BarrageRenderer *barrageRenderer;

- (void)loadPlayerWithInfo:(DYRoomInfo *)info;
- (void)destroyPlayer;
@end
