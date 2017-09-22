//
//  DouyuTVSocket.h
//  DouyuTVDammu
//
//  Created by LuChen on 16/2/26.
//  Copyright © 2016年 Bad Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "ServerModel.h"
#import "NSString+InfoGet.h"
#import "SocketData.h"

/*
  向斗鱼发送的消息
  1.通信协议长度,后四个部分的长度,四个字节
  2.第二部分与第一部分一样
  3.请求代码,发送给斗鱼的话,内容为0xb1,0x02, 斗鱼返回的代码为0xb2,0x02
  4.发送内容
  5.末尾字节
 */


struct postPack {
    unsigned int length;
    unsigned int lengthTwice;
    unsigned int postCode;
};
typedef struct postPack PostPack;

static const int kReadTimeOut = -1;
static const unsigned int kMaxBuffer = 1024;
static const unsigned int kPostCode = 0x2b1;
static const unsigned int kEnd = 0;



@interface DouyuTVSocket : NSObject<AsyncSocketDelegate>

@property (nonatomic,strong)AsyncSocket *socket;//Socket对象
@property (nonatomic,strong) NSMutableArray *server;//服务器数组
@property (nonatomic,copy)NSString *room;//房间ID
@property (nonatomic,copy)NSString *vistorID;//游客ID
@property (nonatomic,copy)NSString *groupID;//弹幕组ID
@property (nonatomic,strong)NSTimer *connectTimer;//心跳keep live
@property (nonatomic,strong)NSMutableData *combieData;

- (void)setServerConfig;
- (void)connectSocketHost;
- (void)cutOffSocket;
- (NSData *)packToData:(NSString *)string;


@end
