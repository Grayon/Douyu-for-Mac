//
//  MpvClientOGLView.h
//  Douyu
//
//  Created by Grayon on 2017/9/23.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <mpv/opengl_cb.h>
#import <OpenGL/gl.h>

@interface MpvClientOGLView : NSOpenGLView
@property mpv_opengl_cb_context *mpvGL;
- (void)drawRect;
- (void)fillBlack;
@end
