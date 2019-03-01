//
//  AuthSocket.m
//  DouyuTVDammu
//
//  Created by LuChen on 16/3/2.
//  Copyright © 2016年 Bad Chen. All rights reserved.
//

#import "AuthSocket.h"

static AuthSocket *instance = nil;
@implementation AuthSocket
//单例
+ (id)sharedInstance{
    @synchronized(self) {
        if (instance == nil) {
            
            instance = [[AuthSocket alloc]init];
        }
    }
    return instance;
}

- (void)setServerConfig{
    //转换成model，添加到属性
    ServerModel *model = [ServerModel new];
    model.ip = @"openbarrage.douyutv.com";
    model.port = 8601;
    [self.server addObject:model];
}

#pragma marl --回调方法
//连接成功
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    NSLog(@"---认证服务器连接成功---");
    /*
     验证服务器包
     type@=loginreq/username@=/ct@=0/password@=/roomid@=43053/devid@=479512DA70520865088A9A52B53242FB/rt@=1450509705/vk@=d2494e478b4229e3c98a398c8ae2c8f3/ver@=20150929/
     roomid:房间id
     devid:随机UUID
     rt:时间戳
     vk:时间戳+"7oE9nPEG9xXV69phU31FYCLUagKeYtsF"+devid的字符串拼接结果的MD5值
     ver:版本号
     */
    NSString *devid = [NSString uuid];
    NSString *timeString = [NSString timeString];
    NSString *unMD5vk = [NSString stringWithFormat:@"%@%@%@",timeString,kMagicCode,devid];
    NSString *vk = [unMD5vk getMd5_32Bit];
    
    NSString *postLogin = [NSString stringWithFormat:@"type@=loginreq/username@=/ct@=0/password@=/roomid@=%@/devid@=%@/rt@=%@/vk@=%@/ver@=20150929/",self.room,devid,timeString,vk];
    NSData *postLoginData = [self packToData:postLogin];
    [self.socket writeData:postLoginData withTimeout:30 tag:1];
    
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
        [SocketData readAuthMsg:contents];
    }
    [self.socket readDataWithTimeout:kReadTimeOut buffer:nil bufferOffset:0 maxLength:kMaxBuffer tag:0];
}


//断开链接
- (void)onSocketDidDisconnect:(AsyncSocket *)sock{
    NSLog(@"---认证服务器断开---");
    self.combieData = nil;
}

@end
