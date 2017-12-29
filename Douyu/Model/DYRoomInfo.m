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
    NSString *API_SECRET = @"zNzMV1y4EMxOHS6I5WKm";
    NSArray *cdns = @[@"ws", @"tct", @"ws2", @"dl"];
    NSString *aid = @"wp";
    int ts = [NSDate date].timeIntervalSince1970;
    NSString *suffix = [NSString stringWithFormat:@"room/%@?aid=%@&cdn=%@&client_sys=%@&time=%d",roomId,aid,cdns[0],aid,ts];
    NSString *sign = [[suffix stringByAppendingString:API_SECRET] getMd5_32Bit];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://capi.douyucdn.cn/api/v1/%@&auth=%@",suffix,sign]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setValue:@"Mozilla/5.0 (iPad; CPU OS 8_1_3 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B466 Safari/600.1.4" forHTTPHeaderField:@"User-Agent"];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    __block NSData *roomData = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        roomData = data;
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];

    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
    
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
//        return YES;
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
