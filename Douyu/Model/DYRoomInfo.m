//
//  DYRoomInfo.m
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "DYRoomInfo.h"
#import "NSString+InfoGet.h"

@implementation DYRoomInfo

+ (NSString *)getRoomIdWithString:(NSString *)string {
    NSString *roomId = string;
    if (![roomId isPureInt]) {
        NSString *roomInfoUrl = [@"http://open.douyucdn.cn/api/RoomApi/room/" stringByAppendingString:roomId];
        NSData *roomData = [NSData dataWithContentsOfURL:[NSURL URLWithString:roomInfoUrl]];
        if (!roomData) {
            return nil;
        }
        NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:roomData options:0 error:nil];
        if (!respDic || [respDic[@"error"] intValue] != 0) {
            return nil;
        }
        roomId = respDic[@"data"][@"room_id"];
    }
    return roomId;
}

- (BOOL)getInfoWithRoomId:(NSString *)roomId {
    NSArray *cdns = @[@"ws", @"tct", @"ws2", @"dl"];
    int ts = [NSDate date].timeIntervalSince1970;
    NSString *suffix = [NSString stringWithFormat:@"room/%@?aid=androidhd1&cdn=%@&client_sys=android&time=%d",roomId,cdns[0],ts];
    NSString *API_SECRET = @"Y237pxTx2In5ayGz";
    NSString *sign = [[suffix stringByAppendingString:API_SECRET] getMd5_32Bit];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://capi.douyucdn.cn/api/v1/%@&auth=%@",suffix,sign]];
    NSData *roomData = [NSData dataWithContentsOfURL:url];
    if (!roomData) {
        return NO;
    }
    NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:roomData options:0 error:nil];
    if (!respDic || [respDic[@"error"] intValue] != 0) {
        return NO;
    }
    NSDictionary *roomDic = respDic[@"data"];
    self.showStatus = YES;
    if ([roomDic[@"show_status"] intValue] != 1) {
        self.showStatus = NO;
        return YES;
    }
    NSString *nickName = roomDic[@"nickname"];
    NSString *roomName = roomDic[@"room_name"];
    NSArray *servers = roomDic[@"servers"];
    NSString *rtmpPrefix = roomDic[@"rtmp_url"];
    NSString *rtmpSuffix = roomDic[@"rtmp_live"];
    NSString *videoUrl = [NSString stringWithFormat:@"%@/%@",rtmpPrefix,rtmpSuffix];
    NSString *hlsUrl = roomDic[@"hls_url"];
    if ([roomDic[@"rtmp_multi_bitrate"] isKindOfClass:[NSDictionary class]]) {
        NSString *lowVideoUrl = [NSString stringWithFormat:@"%@/%@",rtmpPrefix,roomDic[@"rtmp_multi_bitrate"][@"middle"]];
        NSString *middleVideoUrl = [NSString stringWithFormat:@"%@/%@",rtmpPrefix,roomDic[@"rtmp_multi_bitrate"][@"middle2"]];
        self.lowVideoUrl = lowVideoUrl;
        self.middleVideoUrl = middleVideoUrl;
    }
    self.roomId = roomId;
    self.roomName = roomName;
    self.nickName = nickName;
    self.servers = servers;
    self.hlsUrl = hlsUrl;
    self.videoUrl = videoUrl;
    return YES;
}

@end
