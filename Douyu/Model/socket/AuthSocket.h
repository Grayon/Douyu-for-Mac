//
//  AuthSocket.h
//  DouyuTVDammu
//
//  Created by LuChen on 16/3/2.
//  Copyright © 2016年 Bad Chen. All rights reserved.
//

#import "DouyuTVSocket.h"

static const NSString *kMagicCode = @"7oE9nPEG9xXV69phU31FYCLUagKeYtsF";

@interface AuthSocket : DouyuTVSocket

@property NSArray *servers;

@property(nonatomic,copy)void(^InfoBlock)(NSString *vistorID,NSString *groupID);
+ (id)sharedInstance;

@end
