//
//  PlayerViewController.m
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "PlayerViewController.h"
#import "BarrageRenderer.h"
#import "BarrageDescriptor.h"
#import "BarrageWalkTextSprite.h"
#import "DYDanmuProvider.h"
#import "MpvClientOGLView.h"

#define RGB(r,g,b,a)    [NSColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define ColorFromRGBHex(rgbValue,alphaValue)                                                                                                \
[NSColor colorWithRed:((float) ((rgbValue & 0xFF0000) >> 16)) / 255.0                                                        \
green:((float) ((rgbValue & 0xFF00) >> 8)) / 255.0                                                           \
blue:((float) (rgbValue & 0xFF)) / 255.0                                                                    \
alpha:alphaValue]

@interface PlayerViewController ()<DYDanmuProviderDelegate> {
    BOOL endFile;
}
@property (weak) IBOutlet MpvClientOGLView *glView;
@property (weak) IBOutlet NSView *loadingView;
@property (strong) DYRoomInfo *roomInfo;
@property (strong) DYDanmuProvider *danmuProvider;
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

static void glupdate(void *ctx)
{
    MpvClientOGLView *glView = (__bridge MpvClientOGLView *)ctx;
    // I'm still not sure what the best way to handle this is, but this
    // works.
    dispatch_async(dispatch_get_main_queue(), ^{
        [glView drawRect];
    });
}

static void *get_proc_address(void *ctx, const char *name)
{
    CFStringRef symbolName = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingASCII);
    void *addr = CFBundleGetFunctionPointerForName(CFBundleGetBundleWithIdentifier(CFSTR("com.apple.opengl")), symbolName);
    CFRelease(symbolName);
    return addr;
}

- (void)loadPlayerWithInfo:(DYRoomInfo *)info {
    self.queue = dispatch_queue_create("mpv.quene", DISPATCH_QUEUE_SERIAL);
    [self.loadingView setWantsLayer:YES];
    [self.loadingView.layer setBackgroundColor:ColorFromRGBHex(0xecebeb, 1).CGColor];
    self.roomInfo = info;
    [self setTitle:[NSString stringWithFormat:@"斗鱼%@-%@",self.roomInfo.roomId,self.roomInfo.roomName]];
    [self.view.window setTitle:self.title];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self playVideo:self.roomInfo.videoUrl];
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
        descriptor.params[@"backgroundColor"] = ColorFromRGBHex(0x2894FF,0.5);
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
    
    [self setMPVOption:"input-default-bindings" :"yes"];
    [self setMPVOption:"vo" :"opengl-cb"];

    [self setMPVOption:"cache-default" :"75000"];
    
    if(self.title){
        [self setMPVOption:"force-media-title" :[self.title UTF8String]];
    }
    [self setMPVOption: "hwdec" : "videotoolbox-copy"];
    [self setMPVOption: "vf" : "lavfi=\"fps=fps=60:round=down\""];
    
    // request important errors
    check_error(mpv_request_log_messages(self.mpv, "warn"));
    
    check_error(mpv_initialize(self.mpv));
    mpv_opengl_cb_context *mpvGL = mpv_get_sub_api(self.mpv, MPV_SUB_API_OPENGL_CB);
    self.glView.mpvGL = mpvGL;
    mpv_opengl_cb_init_gl(mpvGL, NULL, get_proc_address, NULL);
    mpv_opengl_cb_set_update_callback(mpvGL, glupdate, (__bridge void *)self.glView);
    
    dispatch_async(self.queue, ^{
        // Register to be woken up whenever mpv generates new events.
        mpv_set_wakeup_callback(self.mpv, wakeup, (__bridge void *) self);
        
        // Load the indicated file
        const char *cmd[] = {"loadfile", [URL cStringUsingEncoding:NSUTF8StringEncoding], NULL};
        check_error(mpv_command(self.mpv, cmd));
    });
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
    dispatch_async(dispatch_get_main_queue(), ^(void){
        mpv_set_wakeup_callback(self.mpv, NULL,NULL);
        mpv_opengl_cb_uninit_gl(self.glView.mpvGL);
        mpv_detach_destroy(self.mpv);
        self.glView.mpvGL = nil;
        self.mpv = nil;
        [self.glView clearGLContext];
    });
}

- (void)destroyPlayer{
    [self.danmuProvider disconnect];
    [self.barrageRenderer stop];
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



@end
