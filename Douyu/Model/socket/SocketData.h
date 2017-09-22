//
//  SocketData.h
//  DouyuTVDammuAssistant
//
//  Created by LuChen on 16/4/20.
//  Copyright © 2016年 Bad Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SocketData : NSObject

+ (void)douyuData:(NSData *)data isAuthData:(BOOL)yesOrNo;
+ (void)readDanmuMsg:(NSArray *)array;
+ (void)readAuthMsg:(NSArray *)array;

@end
