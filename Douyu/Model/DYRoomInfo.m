//
//  DYRoomInfo.m
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "DYRoomInfo.h"
#import "NSString+InfoGet.h"
#import <JavaScriptCore/JavaScriptCore.h>

@implementation DYRoomInfo

- (NSString *)getRoomIdWithString:(NSString *)string {
    NSString *roomId = string;
    NSString *roomInfoUrl = [@"http://open.douyucdn.cn/api/RoomApi/room/" stringByAppendingString:roomId];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:roomInfoUrl]];
    request.timeoutInterval = 5.0f;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    __block NSData *roomData = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            roomData = data;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];

    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);

    if (!roomData) {
        return nil;
    }
    NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:roomData options:0 error:nil];
    if (!respDic || ![respDic isKindOfClass:[NSDictionary class]] || [respDic[@"error"] intValue] != 0) {
        return nil;
    }
    NSDictionary *roomDic = respDic[@"data"];
    NSString *nickName = roomDic[@"owner_name"];
    NSString *roomName = roomDic[@"room_name"];
    roomId = roomDic[@"room_id"];
    self.roomId = roomId;
    self.roomName = roomName;
    self.nickName = nickName;
    self.showStatus = [roomDic[@"room_status"] intValue] == 1;
    return roomId;
}

- (BOOL)getDouyuDid {
    int random = arc4random() % 1000000;
    NSString *callback = [NSString stringWithFormat:@"jsonp_%d", random];
    NSString *didUrl = [NSString stringWithFormat:@"https://passport.douyu.com/lapi/did/api/get?client_id=1&callback=%@", callback];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:didUrl]];
    request.timeoutInterval = 5.0f;
    [request setValue:@"https://www.douyu.com" forHTTPHeaderField:@"Referer"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    __block NSData *respData = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            respData = data;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];

    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
    NSString *resp = [[NSString alloc] initWithData:respData encoding:NSUTF8StringEncoding];
    NSString *json = [[resp stringByReplacingOccurrencesOfString:callback withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n ()"]];
    NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    if (!respDic || ![respDic isKindOfClass:[NSDictionary class]] || [respDic[@"error"] intValue] != 0) {
        return NO;
    }
    self.did = [respDic valueForKeyPath:@"data.did"];
    return self.did == nil;
}

- (BOOL)getRoomJS:(NSString *)roomId {
    NSString *roomJSURL = [NSString stringWithFormat:@"https://www.douyu.com/swf_api/homeH5Enc?rids=%@",roomId];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:roomJSURL]];
    request.timeoutInterval = 5.0f;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    __block NSData *roomData = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            roomData = data;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];

    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
    NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:roomData options:0 error:nil];
    if (!respDic || ![respDic isKindOfClass:[NSDictionary class]] || [respDic[@"error"] intValue] != 0) {
        return NO;
    }
    self.roomJS = [respDic valueForKeyPath:[NSString stringWithFormat:@"data.room%@", roomId]];
    return self.roomJS == nil;
}

- (BOOL)getInfoWithRoomId:(NSString *)roomId rate:(int)rate  {
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
        [self getDouyuDid];
    });
    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
        [self getRoomJS:roomId];
    });

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    if (!self.did || !self.roomJS) {
        return NO;
    }

    int time = NSDate.date.timeIntervalSince1970;
    NSURL *cryptoJsFileURL = [[NSBundle mainBundle] URLForResource:@"crypto-js" withExtension:@"js"];
    NSURL *domJsFileURL = [[NSBundle mainBundle] URLForResource:@"dom" withExtension:@"js"];
    NSURL *patchJsFileURL = [[NSBundle mainBundle] URLForResource:@"patch" withExtension:@"js"];
    NSURL *debugJsFileURL = [[NSBundle mainBundle] URLForResource:@"debug" withExtension:@"js"];

    NSError *error;
    NSString *cryptoJS = [NSString stringWithContentsOfURL:cryptoJsFileURL encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        return NO;
    }
    NSString *domJS = [NSString stringWithContentsOfURL:domJsFileURL encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        return NO;
    }
    NSString *patchJs = [NSString stringWithContentsOfURL:patchJsFileURL encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        return NO;
    }
    NSString *debugJs = [NSString stringWithContentsOfURL:debugJsFileURL encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        return NO;
    }

    NSString *roomJs = self.roomJS;
    NSRange range = [roomJs rangeOfString:@"function ub98484234"];
    if (range.location == NSNotFound) {
        return NO;
    }
    NSString *ub98484234 = [roomJs substringFromIndex:range.location];
    range = [ub98484234 rangeOfString:@"eval\\((\\w+)\\)" options:NSRegularExpressionSearch];
    if (range.location == NSNotFound) {
        return NO;
    }
    NSString *workflow = [ub98484234 substringWithRange:NSMakeRange(range.location+5, range.length-6)];
    patchJs = [patchJs stringByReplacingOccurrencesOfString:@"{workflow}" withString:workflow];

    roomJs = [roomJs stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"eval(%@);", workflow] withString:patchJs];

    JSContext *jsContext = [JSContext new];
    [jsContext evaluateScript:cryptoJS];
    [jsContext evaluateScript:domJS];
    [jsContext evaluateScript:roomJs];
    [jsContext evaluateScript:debugJs];

    NSDictionary *resultDic = [jsContext evaluateScript:[NSString stringWithFormat:@"ub98484234(%@, '%@', %d)", roomId, self.did, time]].toDictionary;
    if (!resultDic) {
        return NO;
    }
    NSString *result = resultDic[@"result"];
    NSString *postString = [NSString stringWithFormat:@"%@&cdn=&rate=%d&iar=0&ive=0", result, rate];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.douyu.com/lapi/live/getH5Play/%@", roomId]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.timeoutInterval = 5.0f;
    [request setValue:@"Mozilla/5.0 (iPad; CPU OS 8_1_3 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B466 Safari/600.1.4" forHTTPHeaderField:@"User-Agent"];

    request.HTTPMethod = @"POST";
    request.HTTPBody = [postString dataUsingEncoding:NSUTF8StringEncoding];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    __block NSData *roomData = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            roomData = data;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];

    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
    if (!roomData) {
        return NO;
    }
    NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:roomData options:0 error:nil];
    if (!respDic || ![respDic isKindOfClass:[NSDictionary class]] || [respDic[@"error"] intValue] != 0) {
        return NO;
    }
    self.showStatus = YES;
    NSDictionary *roomDic = respDic[@"data"];

    NSString *rtmpPrefix = roomDic[@"rtmp_url"];
    NSString *rtmpSuffix = roomDic[@"rtmp_live"];
    NSString *videoUrl = [NSString stringWithFormat:@"%@/%@",rtmpPrefix,rtmpSuffix];

    self.videoUrl = videoUrl;
    return YES;
}

@end
