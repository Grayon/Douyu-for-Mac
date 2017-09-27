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

#import "BarrageRenderer.h"
#import "BarrageCanvas.h"
#import "BarrageSprite.h"
#import "BarrageSpriteFactory.h"
#import "BarrageDescriptor.h"
#import "NSView+UIView.h"
#import "NSValue+iOS.h"
#import "BarrageWalkTextSprite.h"

NSString * const kBarrageRendererContextCanvasBounds = @"kBarrageRendererContextCanvasBounds";   // 画布大小
NSString * const kBarrageRendererContextRelatedSpirts = @"kBarrageRendererContextRelatedSpirts"; // 相关精灵
NSString * const kBarrageRendererContextTimestamp = @"kBarrageRendererContextTimestamp";         // 时间戳

@interface BarrageRenderer()
{
    BarrageCanvas * _canvas; // 画布
    NSMutableDictionary * _context; // 渲染器上下文
    
    NSMutableArray * _records;//记录数组
}
@property(nonatomic,strong)NSMutableArray *sprites;
@end

@implementation BarrageRenderer
#pragma mark - init
- (instancetype)init
{
    if (self = [super init]) {
        _canvas = [[BarrageCanvas alloc]init];
        _sprites = [[NSMutableArray alloc] init];
        _zIndex = NO;
        _context = [[NSMutableDictionary alloc]init];
        _recording = NO;
    }
    return self;
}

#pragma mark - control
- (void)receive:(BarrageDescriptor *)descriptor
{
    if (!_launched) {
        return;
    }
    BarrageDescriptor * descriptorCopy = [descriptor copy];
    BarrageSprite * sprite = [BarrageSpriteFactory createSpriteWithDescriptor:descriptorCopy];
    [self activeSprite:sprite];
    if (_recording) {
        [self recordDescriptor:descriptorCopy];
    }
}

- (void)start
{
    _launched = YES;
}

- (void)stop
{
    _launched = NO;
    [self.sprites enumerateObjectsUsingBlock:^(BarrageSprite *sprite, NSUInteger idx, BOOL * _Nonnull stop) {
        [sprite.view.layer removeAllAnimations];
        [sprite.view removeFromSuperview];
    }];
    [self.sprites removeAllObjects];
}

#pragma mark - record
/// 此方法会修改desriptor的值
- (void)recordDescriptor:(BarrageDescriptor *)descriptor
{
    __block BOOL exists = NO;
    [_records enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL * stop){
        if([((BarrageDescriptor *)obj).identifier isEqualToString:descriptor.identifier]){
            exists = YES;
            *stop = YES;
        }
    }];
    if(!exists){
        [_records addObject:descriptor];
    }
}

- (NSArray *)records
{
    return [_records copy];
}

#pragma mark - BarrageDispatcherDelegate
- (void)activeSprite:(BarrageSprite *)sprite
{
    NSValue * value = [NSValue valueWithCGRect:_canvas.bounds];
    [_context setObject:value forKey:kBarrageRendererContextCanvasBounds];
    [_context setObject:[self.sprites copy] forKey:kBarrageRendererContextRelatedSpirts];
    [_context setObject:@([[NSDate date] timeIntervalSince1970]) forKey:kBarrageRendererContextTimestamp];
    
    [sprite activeWithContext:_context];
    [_canvas addSubview:sprite.view];
    [self.sprites addObject:sprite];
    
    float speed = [[sprite valueForKey:@"speed"] floatValue];
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.duration = (_canvas.bounds.size.width + sprite.size.width*2)/speed;
    anim.fromValue = [NSValue valueWithCGPoint:sprite.origin];
    anim.toValue = [sprite valueForKey:@"destination"];
    anim.removedOnCompletion = NO;
    anim.fillMode = kCAFillModeForwards;
    [sprite.view.layer addAnimation:anim forKey:nil];
    __weak BarrageSprite *weak_sprite = sprite;
    __weak BarrageRenderer *weak_self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(anim.duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weak_self deactiveSprite:weak_sprite];
    });
}

- (void)deactiveSprite:(BarrageSprite *)sprite
{
    [self.sprites removeObject:sprite];
    [sprite.view removeFromSuperview];
    [sprite.view.layer removeAllAnimations];
}

#pragma mark - attributes

- (NSView *)view
{
    return _canvas;
}

@end
