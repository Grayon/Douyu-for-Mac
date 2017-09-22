//
//  PlayerViewController.m
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "PlayerViewController.h"
#import <mpv/client.h>
#import "BarrageRenderer.h"
#import "BarrageDescriptor.h"
#import "BarrageWalkTextSprite.h"
#import "DYDanmuProvider.h"

#define RGB(r,g,b,a)    [NSColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define ColorFromRGBHex(rgbValue)                                                                                                \
[NSColor colorWithRed:((float) ((rgbValue & 0xFF0000) >> 16)) / 255.0                                                        \
green:((float) ((rgbValue & 0xFF00) >> 8)) / 255.0                                                           \
blue:((float) (rgbValue & 0xFF)) / 255.0                                                                    \
alpha:1.0]

@interface PlayerViewController ()<DYDanmuProviderDelegate> {
    BOOL endFile;
}
@property (weak) IBOutlet NSView *playerView;
@property (weak) IBOutlet NSView *loadingView;
@property (strong) DYRoomInfo *roomInfo;
@property (strong) DYDanmuProvider *danmuProvider;
@property (assign) mpv_handle *mpv;
@property (strong) dispatch_queue_t queue;
@property (strong) BarrageRenderer *barrageRenderer;
@end

@implementation PlayerViewController

void wakeup(void *context) {
    if(context){
        // Damn ARC
        const uint8_t *data_ctx = (uint8_t *)context;
        if(data_ctx[0] == 0x88 && data_ctx[1] == 0x00 && data_ctx[2] == 0x00){
            NSLog(@"Invalid callback context.");
            return;
        }
        PlayerViewController *a = (__bridge PlayerViewController *) context;
        if(a && a.className &&
           [a respondsToSelector:@selector(readEvents)]){
            [a readEvents];
        }
    }
}

void check_error(int status)
{
    if (status < 0) {
        NSLog(@"mpv API error: %s", mpv_error_string(status));
        dispatch_async(dispatch_get_main_queue(), ^(void){
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:@"mpv API error: %s", mpv_error_string(status)]];
            [alert runModal];
        });
    }
}

- (void)loadPlayerWithInfo:(DYRoomInfo *)info {
    self.queue = dispatch_queue_create("mpv.quene", DISPATCH_QUEUE_SERIAL);
    self.roomInfo = info;
    [self setTitle:self.roomInfo.roomName];
    [self.view.window setTitle:self.roomInfo.roomName];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self playVideo:self.roomInfo.lowVideoUrl];
        [self loadDanmu];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)loadDanmu {
    dispatch_async(dispatch_get_main_queue(), ^{
        BarrageRenderer *renderer = [[BarrageRenderer alloc] init];
        [self.view setWantsLayer:YES];
        [renderer.view setFrame:NSMakeRect(0,0,self.view.frame.size.width,self.view.frame.size.height)];
        [renderer.view setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
        [self.view addSubview:renderer.view positioned:NSWindowAbove relativeTo:nil];
        [renderer start];
        self.barrageRenderer = renderer;
        self.danmuProvider = [[DYDanmuProvider alloc] init];
        self.danmuProvider.delegate = self;
        [self.danmuProvider loadWithInfo:self.roomInfo];
    });
}

- (void)onNewMessage:(NSString *)cmContent :(NSString *)userName :(int)ftype :(int)fsize :(NSColor *)color{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if (ftype == 0) {
            [self addSpritToVideo:ftype content:cmContent size:fsize color:color];
        } else {
            [self addSpritToVideo:ftype content:[NSString stringWithFormat:@"  %@：%@  ",userName,cmContent] size:fsize+2 color:color];
        }
    });
}

- (void)addSpritToVideo:(int)type content:(NSString*)content size:(int)size color:(NSColor *)color
{
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageWalkTextSprite class]);
    descriptor.params[@"text"] = content;
    descriptor.params[@"textColor"] = color;
    descriptor.params[@"fontSize"] = @(size);
//    descriptor.params[@"fontFamily"] = @"Helvetica Bold";
    descriptor.params[@"speed"] = @(120+arc4random()%41);
    if (type != 0) {
        descriptor.params[@"backgroundColor"] = ColorFromRGBHex(0x2894FF);
        descriptor.params[@"cornerRadius"] = @(16);
    }
    
    // type is not supported right
    descriptor.params[@"direction"] = @(BarrageWalkDirectionR2L);
    [self.barrageRenderer receive:descriptor];
}

- (void)setMPVOption:(const char *)name :(const char*)data{
    int status = mpv_set_option_string(self.mpv, name, data);
    check_error(status);
}

- (void)playVideo:(NSString *)URL{
    
    // Start Playing Video
    self.mpv  = mpv_create();
    
    
    int64_t wid = (intptr_t) self.playerView;
    check_error(mpv_set_option(self.mpv, "wid", MPV_FORMAT_INT64, &wid));
    
    [self setMPVOption:"input-default-bindings" :"yes"];
    [self setMPVOption:"input-vo-keyboard" :"yes"];
    [self setMPVOption:"input-cursor" :"no"];
    [self setMPVOption:"osc" :"no"];
//    [self setMPVOption:"script-opts" :"osc-layout=box,osc-seekbarstyle=bar"];
//    [self setMPVOption:"user-agent" :[userAgent cStringUsingEncoding:NSUTF8StringEncoding]];
    [self setMPVOption:"framedrop" :"vo"];
    [self setMPVOption:"hr-seek" :"yes"];
//    [self setMPVOption:"fs-black-out-screens" :"yes"];
//    [self setMPVOption:"vo" :"opengl:pbo:dither=no:alpha=no"];
    [self setMPVOption:"screenshot-directory" :"~/Desktop"];
    [self setMPVOption:"screenshot-format" :"png"];
    
    
    [self setMPVOption:"input-media-keys" :"no"];
    
    [self setMPVOption:"cache-default" :"75000"];
    
    if(self.title){
        [self setMPVOption:"force-media-title" :[self.title UTF8String]];
    }
    
    [self setMPVOption: "hwdec" : "videotoolbox-copy"];
    [self setMPVOption: "vf" : "lavfi=\"fps=fps=60:round=down\""];
    
    // request important errors
    check_error(mpv_request_log_messages(self.mpv, "warn"));
    
    check_error(mpv_initialize(self.mpv));
    
    // Register to be woken up whenever mpv generates new events.
    mpv_set_wakeup_callback(self.mpv, wakeup, (__bridge void *) self);
    
    // Load the indicated file
    const char *cmd[] = {"loadfile", [URL cStringUsingEncoding:NSUTF8StringEncoding], NULL};
    check_error(mpv_command(self.mpv, cmd));
}

- (void) readEvents
{
    dispatch_async(self.queue, ^{
        while (self.mpv) {
            mpv_event *event = mpv_wait_event(self.mpv, 0);
            if(!event)
                break;
            if (event->event_id == MPV_EVENT_NONE)
                break;
            if(self && [self respondsToSelector:@selector(handleEvent:)]){
                [self handleEvent:event];
            }else{
                return;
            }
        }
    });
}

- (void) handleEvent:(mpv_event *)event
{
    [self onMpvEvent:event];
    switch (event->event_id) {
        case MPV_EVENT_SHUTDOWN: {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self.view.window performClose:self];
            });
            NSLog(@"Stopping player");
            break;
        }
            
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            NSLog(@"[%s] %s: %s", msg->prefix, msg->level, msg->text);
            break;
        }
            
        case MPV_EVENT_VIDEO_RECONFIG: {
//            NSApplicationPresentationOptions opts = [[NSApplication sharedApplication ] presentationOptions];
//            if (opts & NSApplicationPresentationFullScreen) {
//                NSLog(@"[AutoFS] Already in fullscreen");
//            }else{
//                NSLog(@"[AutoFS] Start fullscreen");
//                [self.view.window toggleFullScreen:self.view.window];
//            }
            break;
        }
            
        case MPV_EVENT_START_FILE:{
            endFile = NO;
            break;
        }
            
        case MPV_EVENT_PLAYBACK_RESTART: {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loadingView setHidden:YES];
            });
            break;
        }
            
        case MPV_EVENT_END_FILE:{
            endFile = YES;
            break;
        }
            
        case MPV_EVENT_IDLE:{
            if(endFile){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.loadingView setHidden:NO];
                    [self.view.window performClose:self];
                });
            }
            break;
        }
            
        case MPV_EVENT_PAUSE: {
            break;
        }
        case MPV_EVENT_UNPAUSE: {
            break;
        }
            
        default: ;
            //NSLog(@"Player Event: %s", mpv_event_name(event->event_id));
    }
}

- (void)onMpvEvent:(mpv_event *)event{
    if(event->event_id == MPV_EVENT_GET_PROPERTY_REPLY || event->event_id == MPV_EVENT_PROPERTY_CHANGE){
        mpv_event_property *propety = event->data;
        void *data = propety->data;
        if(!data){
            return;
        }
        if(strcmp(propety->name, "pause") == 0){
            int paused = *(int *)data;
//            [self onPaused:paused];
        }else if(strcmp(propety->name, "mute") == 0){
            int mute = *(int *)data;
//            [self onMuted:mute];
        }else if(strcmp(propety->name, "sub-visibility") == 0){
            int vis = *(int *)data;
//            [self onSubVisibility:vis];
        }else if(strcmp(propety->name, "options/keepaspect") == 0){
            int keep = *(int *)data;
            [self onKeepAspect:keep];
        }else if(strcmp(propety->name, "volume") == 0){
            double volume = *(double *)data;
//            [self onVolume:volume];
        }else if(strcmp(propety->name, "duration") == 0){
            double duration = *(double *)data;
//            [self onDuration:duration];
        }else if(strcmp(propety->name, "time-pos") == 0){
            double t = *(double *)data;
//            [self onPlaybackTime:t];
        }else if(strcmp(propety->name, "cache-used") == 0){
            double t = *(double *)data;
//            [self onCacheSize:t];
        }else if(strcmp(propety->name, "cache") == 0){
            double t = *(double *)data;
//            [self onCacheFillRate:t];
        }
    }else{
        mpv_event_id event_id = event->event_id;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self onOnlyEventId:event_id];
        });
    }
}

- (void)onOnlyEventId:(mpv_event_id)event_id{
    switch (event_id) {
        case MPV_EVENT_VIDEO_RECONFIG: {
            [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(readInitState)
                                           userInfo:nil repeats:NO];
            break;
        }
        case MPV_EVENT_SEEK: {
//            [self updateTime];
            break;
        }
        default:{
            break;
        }
    }
}

- (void)readInitState{
    if(!self.mpv){
        return;
    }
    mpv_get_property_async(self.mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_get_property_async(self.mpv, 0, "volume", MPV_FORMAT_DOUBLE);
    mpv_get_property_async(self.mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
    mpv_observe_property(self.mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_observe_property(self.mpv, 0, "mute", MPV_FORMAT_FLAG);
    mpv_observe_property(self.mpv, 0, "sub-visibility", MPV_FORMAT_FLAG);
    mpv_observe_property(self.mpv, 0, "options/keepaspect", MPV_FORMAT_FLAG);
    mpv_observe_property(self.mpv, 0, "volume", MPV_FORMAT_DOUBLE);
    mpv_observe_property(self.mpv, 0, "duration", MPV_FORMAT_DOUBLE);
}

- (void)onKeepAspect:(int)keep{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        // call SetFrame to force opengl canvas resize
        NSView *videoView = self.playerView;
        NSRect rect = videoView.frame;
        rect.size.width += 1;
        [videoView setFrame:rect];
        rect.size.width -= 1;
        [videoView setFrame:rect];
    });
}

- (void) mpv_cleanup
{
    dispatch_async(self.queue, ^{
        mpv_set_wakeup_callback(self.mpv, NULL,NULL);
        mpv_terminate_destroy(self.mpv);
        self.mpv = nil;
    });
}
- (void)destroyPlayer{
    [self.danmuProvider disconnect];
    [self mpv_cleanup];
}



@end
