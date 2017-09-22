//
//  DanmuModel.h
//  DouyuTVDammu
//
//  Created by LuChen on 16/3/12.
//  Copyright © 2016年 Bad Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
@class TYTextContainer;

@interface DanmuModel : NSObject

typedef NS_ENUM(NSInteger,CellType){
    CellBanType,
    CellNewChatMessageType,
    CellNewGiftType,
    CellNewUserEnterType,
    CellDeserveType,
};
@property (nonatomic,strong)TYTextContainer *textContainer;
@property (nonatomic,copy)NSString *unColoredMsg;
@property (nonatomic,copy)NSColor *color;
@property (nonatomic,copy)NSString *nickname;
@property (nonatomic,assign) int nc;
@property (nonatomic,assign)CellType cellType;
@property (nonatomic,strong)NSArray *gift;
@property (nonatomic,copy)NSString *dataString;
- (void)setModelFromStirng:(NSString *)string;

@end
