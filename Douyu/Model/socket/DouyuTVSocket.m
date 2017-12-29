//
//  DouyuTVSocket.m
//  DouyuTVDammu
//
//  Created by LuChen on 16/2/26.
//  Copyright © 2016年 Bad Chen. All rights reserved.
//

#import "DouyuTVSocket.h"




@implementation DouyuTVSocket

- (void)setServerConfig{
    
}

//连接服务器
- (void)connectSocketHost{
    self.socket = [[AsyncSocket alloc] initWithDelegate:self];
    [self setServerConfig];
    NSError *error = nil;
    ServerModel *sevCfg = self.server[0];

    [self.socket connectToHost:sevCfg.ip onPort:sevCfg.port withTimeout:30 error:&error];
    
}
//用户切断链接
- (void)cutOffSocket{
    NSString *logout = @"type@=logout/";
    NSData *logoutData = [self packToData:logout];
    [self.socket writeData:logoutData withTimeout:30 tag:1];
    [self.connectTimer invalidate];
    [self.socket disconnectAfterWriting];
}
//心跳包
- (void)longConnectToSocket{
    
    //keep live 所发送的信息
}

#pragma marl --回调方法
//连接成功
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    

}
//断开链接
- (void)onSocketDidDisconnect:(AsyncSocket *)sock{

}

//发送消息成功之后回调
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    //读取消息
    [self.socket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:kMaxBuffer tag:0];
}
//接受数据
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    if (data.length != 0){
        if (self.combieData == nil) {
            self.combieData = [[NSMutableData alloc]init];
        }
        [self.combieData appendData:data];
        NSMutableArray *contents = @[].mutableCopy;
        while (self.combieData.length > 12) {
            NSUInteger length = 0;
            [self.combieData getBytes:&length length:4];
            length += 4;
            if (self.combieData.length >= length) {
                NSData *contentData = [self.combieData subdataWithRange:NSMakeRange(12,length-12)];
                NSString *content = [[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding];
                if (content) {
                    [contents addObject:content];
                }
                self.combieData = [self.combieData subdataWithRange:NSMakeRange(length, self.combieData.length-length)].mutableCopy;
            } else {
                break;
            }
        }
        [SocketData readDanmuMsg:contents];
    }
    [self.socket readDataWithTimeout:kReadTimeOut buffer:nil bufferOffset:0 maxLength:kMaxBuffer tag:0];
}

- (NSData *)packToData:(NSString *)string{
    NSMutableData *stringData = [string stringToHexData];
    unsigned int hexLength = (int)string.length+9;
    PostPack pack = {hexLength,hexLength,kPostCode};
    
    NSMutableData *postDate = [NSData dataWithBytes:&pack length:sizeof(pack)].mutableCopy;
    [postDate appendData:stringData];
    [postDate appendBytes:&kEnd length:1];
    return postDate;
}

@end
