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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class BarrageDescriptor;
@class BarrageRenderer;

/// 弹幕渲染器
@interface BarrageRenderer : NSObject

#pragma mark - life cycle
@property BOOL launched;

#pragma mark - control

/// 启动弹幕
- (void)start;

/// 停止弹幕渲染, 会清空所有; 再发弹幕就无效了; 一切都会停止;
/// 此方法在不再需要弹幕的时候必须调用,否则可能造成内存泄露.
- (void)stop;

/// 接收弹幕消息, 如果尚未start, 则调用无效.
- (void)receive:(BarrageDescriptor *)descriptor;

#pragma mark - output

/// 返回给外部的view
@property(nonatomic,weak)NSView * view;

/// 逻辑时间
@property(nonatomic,assign,readonly)NSTimeInterval time;

#pragma mark - z-index

/// 是否开启z-index功能,开启之后,性能会稍有降低,绘图会按照z_index进行,值越大,越靠上;默认关闭.
@property(nonatomic,assign)BOOL zIndex;

#pragma mark - record

/// 如需要记录,需要在运行start之后立即运行此函数,内部会通过时间差计算delay;
/// 记录弹幕,可能会序列化到本地; 默认为NO.
@property(nonatomic,assign)BOOL recording;

/// 弹幕记录数组.
- (NSArray *)records;

@end
