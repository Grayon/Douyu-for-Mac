//
//  MpvClientOGLView.m
//  Douyu
//
//  Created by liuhaichao on 2017/9/23.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "MpvClientOGLView.h"

@implementation MpvClientOGLView

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self setWantsBestResolutionOpenGLSurface:YES];
        NSOpenGLPixelFormatAttribute attributes[] = {
            NSOpenGLPFADoubleBuffer,
            0
        };
        [self setPixelFormat:[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes]];
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        // swap on vsyncs
        GLint swapInt = 1;
        [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
        [[self openGLContext] makeCurrentContext];
        self.mpvGL = nil;
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
    if (self.mpvGL) {
        NSRect rect = [self convertRectToBacking:[self bounds]];
        mpv_opengl_cb_draw(self.mpvGL, 0, rect.size.width, -rect.size.height);
    }
    else
        [self fillBlack];
    [[self openGLContext] flushBuffer];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self drawRect];
}
@end
