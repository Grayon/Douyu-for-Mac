//
//  PlayerViewController.m
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "PlayerViewController.h"
#import "BarrageDescriptor.h"
#import "BarrageWalkTextSprite.h"
#import "DYDanmuProvider.h"


#define RGB(r,g,b,a)    [NSColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define ColorFromRGBHex(rgbValue,alphaValue)                                                                                                 \
[NSColor colorWithRed:((float) ((rgbValue & 0xFF0000) >> 16)) / 255.0                                                        \
green:((float) ((rgbValue & 0xFF00) >> 8)) / 255.0                                                           \
blue:((float) (rgbValue & 0xFF)) / 255.0                                                                    \
alpha:alphaValue]

static void *get_proc_address(void *ctx, const char *name)
{
    CFStringRef symbolName = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingASCII);
    void *addr = CFBundleGetFunctionPointerForName(CFBundleGetBundleWithIdentifier(CFSTR("com.apple.opengl")), symbolName);
    CFRelease(symbolName);
    return addr;
}

static void glupdate(void *ctx)
{
    MpvClientOGLView *glView = (__bridge MpvClientOGLView *)ctx;
    // I'm still not sure what the best way to handle this is, but this
    // works.
    dispatch_async(dispatch_get_main_queue(), ^{
        [glView drawRect];
    });
}

@interface PlayerViewController ()<DYDanmuProviderDelegate> {
    BOOL endFile;
    NSTimer *hideCursorTimer;
}

@property (weak, nonatomic) IBOutlet NSView *loadingView;
@property (strong, nonatomic) DYRoomInfo *roomInfo;
@property (strong, nonatomic) DYDanmuProvider *danmuProvider;
@property (strong, nonatomic) dispatch_queue_t queue;
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

void check_error(int status) {
    if (status < 0) {
        NSLog(@"mpv API error: %s", mpv_error_string(status));
        dispatch_async(dispatch_get_main_queue(), ^(void){
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:@"mpv API error: %s", mpv_error_string(status)]];
            [alert runModal];
        });
    }
}

- (void)loadPlayerWithInfo:(DYRoomInfo *)info withVideoQuality:(NSInteger)quality {
    [self.loadingView setWantsLayer:YES];
    [self.loadingView.layer setBackgroundColor:ColorFromRGBHex(0xecebeb, 1).CGColor];
    self.roomInfo = info;
    [self setTitle:[NSString stringWithFormat:@"【%@（%@）】%@",self.roomInfo.nickName,self.roomInfo.roomId,self.roomInfo.roomName]];
    [self.view.window setTitle:self.title];
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (quality) {
            case 2:{
                if (self.roomInfo.lowVideoUrl.length > 0) {
                    [self playVideo:self.roomInfo.lowVideoUrl];
                    break;
                }
            }
            case 1:{
                if (self.roomInfo.middleVideoUrl.length > 0) {
                    [self playVideo:self.roomInfo.middleVideoUrl];
                    break;
                }
            }
            case 0:{
                [self playVideo:self.roomInfo.videoUrl];
                break;
            }
            default:
                [self playVideo:self.roomInfo.videoUrl];
                break;
        }
        [self loadDanmu];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    if(hideCursorTimer){
        [hideCursorTimer invalidate];
        hideCursorTimer = nil;
    }
    hideCursorTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideCursor) userInfo:nil repeats:YES];
}

- (void)hideCursor{
    NSInteger windowId = [NSWindow windowNumberAtPoint:[NSEvent mouseLocation] belowWindowWithWindowNumber:0];
    if(windowId == self.view.window.windowNumber){
        if (CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGEventMouseMoved) >= 5) {
            [NSCursor setHiddenUntilMouseMoves:YES];
        }
    }
}

- (void)loadDanmu {
    self.danmuProvider = [[DYDanmuProvider alloc] init];
    self.danmuProvider.delegate = self;
    [self.danmuProvider loadWithInfo:self.roomInfo];
    [self.barrageRenderer start];
    [self.view addSubview:self.barrageRenderer.view positioned:NSWindowAbove relativeTo:nil];
}

- (void)onNewMessage:(NSString *)cmContent :(NSString *)userName :(int)ftype :(int)fsize :(NSColor *)color{
    if (ftype == 0) {
        [self addSpritToVideo:ftype content:cmContent size:fsize color:color];
    } else {
        [self addSpritToVideo:ftype content:[NSString stringWithFormat:@"  %@：%@  ",userName,cmContent] size:fsize+2 color:color];
    }
}

- (void)addSpritToVideo:(int)type content:(NSString*)content size:(int)size color:(NSColor *)color
{
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageWalkTextSprite class]);
    descriptor.params[@"text"] = content;
    descriptor.params[@"textColor"] = color;
    descriptor.params[@"fontSize"] = @(size);
    descriptor.params[@"fontFamily"] = @"Helvetica Bold";
    descriptor.params[@"speed"] = @(120+arc4random()%61);
    if (type != 0) {
        descriptor.params[@"backgroundColor"] = ColorFromRGBHex(0x2894FF,0.5);
        descriptor.params[@"cornerRadius"] = @(16);
    }

    // type is not supported right
    descriptor.params[@"direction"] = @(BarrageWalkDirectionR2L);
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.barrageRenderer receive:descriptor];
    });
}

- (void)setMPVOption:(const char *)name :(const char*)data{
    int status = mpv_set_option_string(self.mpv, name, data);
    check_error(status);
}

- (void)playVideo:(NSString *)URL{

    // Start Playing Video
    self.mpv = mpv_create();

    [self setMPVOption:"input-default-bindings" :"yes"];

    [self setMPVOption:"cache-default" :"75000"];

    if(self.title){
        [self setMPVOption:"force-media-title" :[self.title UTF8String]];
    }
    [self setMPVOption:"hwdec" : "auto"];
    [self setMPVOption:"opengl-hwdec-interop" :"auto"];
//    [self setMPVOption: "vf" : "lavfi=\"fps=60:round=down\""];
    [self setMPVOption:"vo" :"libmpv"];
    [self loadMPVSettings];
    // request important errors
    check_error(mpv_request_log_messages(self.mpv, "warn"));
    
    check_error(mpv_initialize(self.mpv));
    mpv_render_param mpv_params[] = {
        {MPV_RENDER_PARAM_API_TYPE, MPV_RENDER_API_TYPE_OPENGL},
        {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &(mpv_opengl_init_params){
            .get_proc_address = get_proc_address,
        }},
        {0}
    };

    mpv_render_context *mpvGLContext;
    check_error(mpv_render_context_create(&mpvGLContext, self.mpv, mpv_params));
    self.glView.mpvGL = mpvGLContext;
    mpv_render_context_set_update_callback(mpvGLContext, glupdate, (__bridge void *)self.glView);

    dispatch_async(self.queue, ^{
        // Register to be woken up whenever mpv generates new events.
        mpv_set_wakeup_callback(self.mpv, wakeup, (__bridge void *) self);

        // Load the indicated file
        const char *cmd[] = {"loadfile", [URL cStringUsingEncoding:NSUTF8StringEncoding], NULL};
        check_error(mpv_command(self.mpv, cmd));
    });
}

- (void) loadMPVSettings{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    NSString *confDir = [NSString stringWithFormat:@"%@/Douyu/conf/",applicationSupportDirectory];

    BOOL isDir = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:confDir isDirectory:&isDir];
    if(!isExist){
        [[NSFileManager defaultManager] createDirectoryAtPath:confDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    mpv_set_option_string(self.mpv, "config-dir",[confDir UTF8String]);
    [self setMPVOption:"config" :"yes"];
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
            if ([NSThread isMainThread]) {
                [self.view.window performClose:self];
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.view.window performClose:self];
                });
            }
            NSLog(@"Stopping player");
            break;
        }
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            NSLog(@"[%s] %s: %s", msg->prefix, msg->level, msg->text);
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
                if ([NSThread isMainThread]) {
                    [self.loadingView setHidden:NO];
                    [self.view.window performClose:self];
                } else {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.loadingView setHidden:NO];
                        [self.view.window performClose:self];
                    });
                }
            }
            break;
        }
        case MPV_EVENT_VIDEO_RECONFIG:{
            mpv_observe_property(self.mpv, 0, "options/keepaspect", MPV_FORMAT_FLAG);
            break;
        }
        default: ;
            //NSLog(@"Player Event: %s", mpv_event_name(event->event_id));
    }
}

- (void) mpv_cleanup
{
    mpv_set_wakeup_callback(self.mpv, NULL,NULL);
    mpv_render_context_free(self.glView.mpvGL);
    mpv_terminate_destroy(self.mpv);
    self.glView.mpvGL = nil;
    self.mpv = nil;
    [self.glView clearGLContext];
    [self.glView removeFromSuperview];
    self.glView = nil;
}

- (void)destroyPlayer{
    [self.view setWantsLayer:NO];
    [hideCursorTimer invalidate];
    hideCursorTimer = nil;
    [self.danmuProvider disconnect];
    [self.barrageRenderer stop];
    [self.barrageRenderer.view removeFromSuperview];
    [self mpv_cleanup];
}

- (void)onMpvEvent:(mpv_event *)event{
    if(event->event_id == MPV_EVENT_GET_PROPERTY_REPLY || event->event_id == MPV_EVENT_PROPERTY_CHANGE){
        mpv_event_property *propety = event->data;
        void *data = propety->data;
        if(!data){
            return;
        }
        if(strcmp(propety->name, "options/keepaspect") == 0){
            int keep = *(int *)data;
            [self onKeepAspect:keep];
        }
    }
}

- (void)onKeepAspect:(int)keep{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        // call SetFrame to force opengl canvas resize
        NSView *videoView = self.glView;
        NSRect rect = videoView.frame;
        rect.size.width += 1;
        [videoView setFrame:rect];
        rect.size.width -= 1;
        [videoView setFrame:rect];
    });
}

#pragma mark - lazy init

- (BarrageRenderer *)barrageRenderer {
    if (!_barrageRenderer) {
        BarrageRenderer *renderer = [[BarrageRenderer alloc] init];
        [self.view setWantsLayer:YES];
        [renderer.view setFrame:NSMakeRect(0,0,self.view.frame.size.width,self.view.frame.size.height)];
        [renderer.view setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
        [renderer.view setWantsLayer:YES];
        _barrageRenderer = renderer;
    }
    return _barrageRenderer;
}

- (dispatch_queue_t)queue {
    if (!_queue) {
        _queue = dispatch_queue_create("douyu.mpv.quene", DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}


@end
