//
//  DanmuSocket.h
//  DouyuTVDammu
//
//  Created by LuChen on 16/3/3.
//  Copyright © 2016年 Bad Chen. All rights reserved.
//

#import "DouyuTVSocket.h"

@interface DanmuSocket : DouyuTVSocket

@property (nonatomic,assign)BOOL isFirstDate;

+ (id)sharedInstance;
- (void)startKLTimer;
@end
