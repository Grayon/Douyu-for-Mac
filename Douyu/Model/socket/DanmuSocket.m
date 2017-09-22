//
//  DanmuSocket.m
//  DouyuTVDammu
//
//  Created by LuChen on 16/3/3.
//  Copyright © 2016年 Bad Chen. All rights reserved.
//

#import "DanmuSocket.h"

static DanmuSocket *instance = nil;
@implementation DanmuSocket

+ (id)sharedInstance{
    @synchronized(self) {
        if (instance == nil) {
            
            instance = [[DanmuSocket alloc]init];
        }
    }
    return instance;
}

- (void)setServerConfig{
    NSString *ip = @"danmu.douyutv.com";
    NSArray *sevArray = @[@{@"ip":ip,@"port":@"12061"},
                        @{@"ip":ip,@"port":@"12062"},
                        @{@"ip":ip,@"port":@"8601"},
                        @{@"ip":ip,@"port":@"8602"},
                        ];
    self.server = @[].mutableCopy;
    for (int i = 0; i < sevArray.count; i++) {
        ServerModel *model = [ServerModel new];
        NSDictionary *sevCfg = sevArray[i];
        model.ip = sevCfg[@"ip"];
        model.port = [sevCfg[@"port"] intValue];
        [self.server addObject:model];
    }

}

- (void)connectSocketHost{
    self.socket = [[AsyncSocket alloc]initWithDelegate:self];

    NSError *error = nil;
    NSString *ip = @"danmu.douyutv.com";
    UInt16 port = 8602;
    
    [self.socket connectToHost:ip onPort:port withTimeout:30 error:&error];
    
}

//心跳包
- (void)longConnectToSocket{
    //keep live 所发送的信息
    /*
     心跳包内容
     type@=mrkl/
     */
    NSString *keepLive = @"type@=mrkl/";
    NSData *postKLData = [self packToData:keepLive];
    [self.socket writeData:postKLData withTimeout:30 tag:1];
    
}


#pragma marl --回调方法
//连接成功
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    NSLog(@"---弹幕服务器连接成功---");

    /*
     游客登陆信息
     type@=loginreq/username@=visitor13227520/password@=1234567890123456/roomid@=213116/
     username:
     roomid:
     加入弹幕组
     type@=joingroup/rid@=213116/gid@=1/
     */
    NSString *danmuLogin = [NSString stringWithFormat:@"type@=loginreq/username@=%@/password@=1234567890123456/roomid@=%@/",self.vistorID,self.room];
    NSData *postLoginData = [self packToData:danmuLogin];
    self.isFirstDate = YES;
    [self.socket writeData:postLoginData withTimeout:30 tag:1];
    
}
//断开链接
- (void)onSocketDidDisconnect:(AsyncSocket *)sock{
    NSLog(@"----弹幕服务器断开----");

}


//接受数据 从父类继承
//- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
//}

- (void)startKLTimer{
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    [self.connectTimer fire];
}


@end
