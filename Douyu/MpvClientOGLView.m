//
//  MpvClientOGLView.m
//  Douyu
//
//  Created by Grayon on 2017/9/23.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "MpvClientOGLView.h"

@interface MpvClientOGLView (){
    NSRect rect;
}

@end

@implementation MpvClientOGLView

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self setWantsBestResolutionOpenGLSurface:YES];
        rect = [self convertRectToBacking:[self bounds]];
    }
    return self;
}

- (void)fillBlack
{
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)drawRect
{
    if (self.mpvGL && !self.pause) {
        mpv_render_param params[] = {
            // Specify the default framebuffer (0) as target. This will
            // render onto the entire screen. If you want to show the video
            // in a smaller rectangle or apply fancy transformations, you'll
            // need to render into a separate FBO and draw it manually.
            {MPV_RENDER_PARAM_OPENGL_FBO, &(mpv_opengl_fbo){
                .fbo = 0,
                .w = rect.size.width,
                .h = rect.size.height,
            }},
            // Flip rendering (needed due to flipped GL coordinate system).
            {MPV_RENDER_PARAM_FLIP_Y, &(int){1}},
            {0}
        };
        mpv_render_context_render(self.mpvGL, params);
    }
    else{
        rect = [self convertRectToBacking:[self bounds]];
        [self fillBlack];
    }
    glFlush();
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self drawRect];
}
@end
