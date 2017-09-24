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
        mpv_opengl_cb_draw(self.mpvGL, 0, rect.size.width, -rect.size.height);
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
