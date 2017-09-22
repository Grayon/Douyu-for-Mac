//
//  Settings.m
//  Douyu
//
//  Created by Grayon on 2017/9/22.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "Settings.h"

@implementation Settings

+ (instancetype)shareInstance {
    static Settings *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self) {
        self = [super init];
    }
    return self;
}

@end
