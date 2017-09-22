//
//  SocketData.m
//  DouyuTVDammuAssistant
//
//  Created by LuChen on 16/4/20.
//  Copyright © 2016年 Bad Chen. All rights reserved.
//

#import "SocketData.h"
#import "AuthSocket.h"
#import "DanmuSocket.h"


@implementation SocketData


+ (void)douyuData:(NSData *)data isAuthData:(BOOL)yesOrNo{
    NSMutableArray *contents = @[].mutableCopy;
    NSData *subData = data.copy;
    NSUInteger _loction = 0;
    NSUInteger _length = 0;
    do {
        
        //获取数据长度
        if (subData.length < 12) {
            break;
        }
        [subData getBytes:&_length range:NSMakeRange(0, 4)];
        _length -= 12;
        //截取相对应的数据
//        NSLog(@"subdatelength:%lu,range.loaction:%d,range.length:%lu",(unsigned long)subData.length,12,_length);
        NSData *contentData = [subData subdataWithRange:NSMakeRange(12, _length)];
        NSString *content = [[NSString alloc]initWithData:contentData encoding:NSUTF8StringEncoding];
        //截取余下的数据
        _loction += 12;
//        NSLog(@"datelength:%lu,range.loaction:%ld,range.length:%lu",(unsigned long)data.length,_length+_loction,data.length-_length-_loction);
        subData = [data subdataWithRange:NSMakeRange(_length+_loction, data.length-_length-_loction)];
        if (content) {
            [contents addObject:content];
        }
        
        _loction += _length;
        
    } while (_loction < data.length);
    if (yesOrNo) {
        [self readAuthMsg:contents];
    }else{
        [self readDanmuMsg:contents];
    }
    
    
}
+ (void)readDanmuMsg:(NSArray *)array{
    DanmuSocket *danmuSocket = [DanmuSocket sharedInstance];
    for (NSString * msg in array) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"kReceiveDYMessageNotification" object:msg];
        if (!danmuSocket.connectTimer.isValid) {
            if ([msg rangeOfString:@"type@=login"].location != NSNotFound) {
                //加入弹幕组
                NSString *jionGroup = [NSString stringWithFormat:@"type@=joingroup/rid@=%@/gid@=%@/",danmuSocket.room,@"-9999"];//danmuSocket.groupID
                NSData *jGroupData = [danmuSocket packToData:jionGroup];
                [danmuSocket.socket writeData:jGroupData withTimeout:30 tag:1];
                //开始发送心跳包
                [danmuSocket startKLTimer];
            }
        }
    }
}
+ (void)readAuthMsg:(NSArray *)array{
    AuthSocket *authSocket = [AuthSocket sharedInstance];
    //遍历数组，提取ID
    for (NSString *msg in array) {
        
        if ([msg rangeOfString:@"loginres"].location != NSNotFound && [msg rangeOfString:@"username@="].location != NSNotFound) {
            NSRange range = [msg rangeOfString:@"username@="];
            NSString *unSubString = [msg substringFromIndex:range.location + range.length];
            authSocket.vistorID = [unSubString substringToIndex:[unSubString rangeOfString:@"/"].location];
        }
        if ([msg rangeOfString:@"gid@="].location != NSNotFound) {
            NSRange range = [msg rangeOfString:@"gid@="];
            NSString *unSubSring = [msg substringFromIndex:range.location + range.length];
            authSocket.groupID = [unSubSring substringToIndex:[unSubSring rangeOfString:@"/"].location];
        }
    }
    //将2个ID传出去
    if (authSocket.vistorID.length != 0 && authSocket.groupID.length != 0) {
        NSLog(@"---获得游客ID以及弹幕组---");
        
        authSocket.InfoBlock(authSocket.vistorID,authSocket.groupID);
        [authSocket cutOffSocket];
    }
}

@end
