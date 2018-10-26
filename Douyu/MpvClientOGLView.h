//
//  MpvClientOGLView.h
//  Douyu
//
//  Created by Grayon on 2017/9/23.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <mpv/render_gl.h>
#import <OpenGL/gl.h>

@interface MpvClientOGLView : NSOpenGLView
@property mpv_render_context *mpvGL;
@property BOOL pause;
- (void)drawRect;
- (void)fillBlack;
@end
