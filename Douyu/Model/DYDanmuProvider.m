//
//  DYDanmuProvider.m
//  vp_tucao
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "DYDanmuProvider.h"
#import "DanmuSocket.h"
#import "AuthSocket.h"
#import "DanmuModel.h"

@interface DYDanmuProvider ()

@property (nonatomic, strong) AuthSocket *authSocket;
@property (nonatomic, strong) DanmuSocket *danmuSocket;

@end


@implementation DYDanmuProvider

- (void)loadWithInfo:(DYRoomInfo *)roomInfo {
    _authSocket = [AuthSocket sharedInstance];
    _authSocket.room = roomInfo.roomId;
    _authSocket.servers = roomInfo.servers;
    [_authSocket connectSocketHost];
    _danmuSocket = [DanmuSocket sharedInstance];
    _danmuSocket.room = _authSocket.room;
    //weak处理防止block循环
    __weak DanmuSocket *danmuSocket = _danmuSocket;
    _authSocket.InfoBlock = ^(NSString *vistorID,NSString *groupID){
        danmuSocket.vistorID = vistorID;
        danmuSocket.groupID = groupID;
        [danmuSocket connectSocketHost];
    };
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMessageNotification:) name:@"kReceiveDYMessageNotification" object:nil];
}

- (void)receiveMessageNotification:(NSNotification *)notification {
    
    NSString *string = notification.object;
    //判断消息类型
    if ([string rangeOfString:@"type@=mrkl"].location == NSNotFound) {
        DanmuModel *model = [DanmuModel new];
        if ([string rangeOfString:@"type@=chatmsg"].location != NSNotFound) {
            model.cellType = CellNewChatMessageType;
            
        }else if ([string rangeOfString:@"type@=dgb"].location != NSNotFound){
            model.cellType = CellNewGiftType;
            
        }else if ([string rangeOfString:@"type@=uenter"].location != NSNotFound){
            model.cellType = CellNewUserEnterType;
            
        }else if ([string rangeOfString:@"type@=blackres"].location != NSNotFound){
            model.cellType = CellBanType;
            
        }else if ([string rangeOfString:@"type@=bc_buy_deserve"].location != NSNotFound){
            model.cellType = CellDeserveType;
        }else{
//            NSLog(@"%@",string);
            model = nil;
            return;
        }
        if (model.cellType == CellNewChatMessageType) {
            [model setModelFromStirng:string];
//            NSLog(@"chatmsg=%@",model.dataString);
            [self.delegate onNewMessage:model.unColoredMsg :model.nickname :model.nc :24 :model.color];
        }
        
        
    }
    
}

- (void)disconnect{
    [_authSocket cutOffSocket];
    [_danmuSocket cutOffSocket];
}



@end
