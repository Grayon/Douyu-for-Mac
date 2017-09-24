// Part of BarrageRenderer. Created by UnAsh.
// Blog: http://blog.exbye.com
// Github: https://github.com/unash/BarrageRenderer

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2015年 UnAsh.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BarrageSprite.h"

@interface BarrageSprite() {
    NSPoint _oldPosition;
}

@end

@implementation BarrageSprite

@synthesize backgroundColor = _backgroundColor;
@synthesize borderWidth = _borderWidth;
@synthesize borderColor = _borderColor;
@synthesize cornerRadius = _cornerRadius;
@synthesize mandatorySize = _mandatorySize;

@synthesize origin = _origin;
@synthesize valid = _valid;
@synthesize view = _view;

- (instancetype)init
{
    if (self = [super init]) {
        _delay = 0.0f;
        _birth = [NSDate date];
        _valid = YES;
        _origin.x = _origin.y = MAXFLOAT;
        _z_index = 0;
        
        _backgroundColor = [NSColor clearColor];
        _borderWidth = 0.0f;
        _borderColor = [NSColor clearColor];
        _cornerRadius = 0.0f;
        _mandatorySize = CGSizeZero;
    }
    return self;
}

#pragma mark - update

- (void)updateWithTime:(NSTimeInterval)time
{
    _valid = [self validWithTime:time];
    _view.frame = [self rectWithTime:time];
}

- (CGRect)rectWithTime:(NSTimeInterval)time
{
    return CGRectMake(_origin.x, _origin.y, self.size.width, self.size.height);
}

- (BOOL)validWithTime:(NSTimeInterval)time
{
    return YES;
}

#pragma mark - launch

- (void)activeWithContext:(NSDictionary *)context
{
    CGRect rect = [[context objectForKey:kBarrageRendererContextCanvasBounds]CGRectValue];
    NSArray * sprites = [context objectForKey:kBarrageRendererContextRelatedSpirts];
    NSTimeInterval timestamp = [[context objectForKey:kBarrageRendererContextTimestamp]doubleValue];
    _timestamp = timestamp;
    _view = [self bindingView];
    [self configView];
    if (!CGSizeEqualToSize(_mandatorySize, CGSizeZero)) {
        _view.frame = CGRectMake(0, 0, _mandatorySize.width, _mandatorySize.height);
    }
//    [_view setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
    _origin = [self originInBounds:rect withSprites:sprites];
    _oldPosition = NSMakePoint(rect.size.width - _origin.x, rect.size.height - _origin.y);
    _view.frame = CGRectMake(_origin.x, _origin.y, self.size.width, self.size.height);
}

//- (CGPoint)origin {
//    NSRect rect = _view.superview.bounds;
//    if (rect.size.width - _origin.x != _oldPosition.x) {
//        _origin = NSMakePoint(rect.size.width - _oldPosition.x, rect.size.height - _oldPosition.y);
//    }
//    return _origin;
//}

- (void)configView
{
    if (self.borderWidth || self.cornerRadius) {
        [_view setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    }
    if (self.cornerRadius) {
        _view.layer.cornerRadius = self.cornerRadius;
        //_view.clipsToBounds = YES;
    }
    if (self.borderColor) {
        _view.layer.borderColor = self.borderColor.CGColor;
    }
    if (self.borderWidth) {
        _view.layer.borderWidth = self.borderWidth;
    }
    if (self.backgroundColor) {
       _view.layer.backgroundColor = [self.backgroundColor CGColor];
    }
}

/// 返回绑定的view
- (NSView *)bindingView
{
    return [[NSView alloc]init];
}

///  区域内的初始位置,只在刚加入渲染器的时候被调用;子类继承需要override.
- (CGPoint)originInBounds:(CGRect)rect withSprites:(NSArray *)sprites
{
    CGFloat x = random_between(rect.origin.x, rect.origin.x+rect.size.width-self.size.width);
    CGFloat y = random_between(rect.origin.y, rect.origin.y+rect.size.height-self.size.height);
    return CGPointMake(x, y);
}

#pragma mark - attributes

- (CGPoint)position
{
    return self.view.frame.origin;
}

- (CGSize)size
{
    return self.view.bounds.size;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
#ifdef DEBUG
    NSLog(@"[Class:%@] hasNo - [Property:%@]; [Value:%@] will be discarded.",NSStringFromClass([self class]),key,value);
#endif
}

@end
