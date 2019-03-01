//
//  ViewController.m
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "ViewController.h"
#import "DYRoomInfo.h"
#import "PlayerViewController.h"
#import "DYRoomHistoryModel.h"

@interface ViewController ()<NSWindowDelegate,NSComboBoxDataSource,NSComboBoxDelegate> {
    NSTimer *resizingTimer;
}

@property (strong, nonatomic) NSWindowController *playerWindowController;
@property (weak, nonatomic) PlayerViewController *playerViewController;
@property (strong, nonatomic) id <NSObject> playingActivity;
@property (strong, nonatomic) NSArray<DYRoomHistoryData *> *roomHistory;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    NSInteger videoQuality = [[NSUserDefaults standardUserDefaults] integerForKey:@"videoQuality"];
    [self.videoQualityButton selectItemAtIndex:videoQuality];
    self.roomComboBox.dataSource = self;
    self.roomComboBox.delegate = self;
    [self reloadHistory];
    if (self.roomHistory.count) {
        [self.roomComboBox selectItemAtIndex:0];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openUrlNorification:) name:@"openUrl" object:nil];
}

- (void)openUrlNorification:(NSNotification *)notification {
    NSArray<NSURL *> *urls = notification.object;
    NSURL *url = urls.firstObject;
    if ([url.host isEqualToString:@"room"]) {
        if (url.lastPathComponent.length) {
            [self.playerWindowController.window performClose:nil];
            [self playWithRoomString:url.lastPathComponent];
        }
    }
}

- (void)viewWillAppear {
    [self reloadHistory];
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)comboBox {
    return self.roomHistory.count;
}

- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(NSInteger)index{
    DYRoomHistoryData *roomData = self.roomHistory[index];
    return [NSString stringWithFormat:@"%@(%@)",roomData.nickname,roomData.roomId];
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.roomComboBox.stringValue = self.roomHistory[self.roomComboBox.indexOfSelectedItem].roomId;
    });
}

- (void)reloadHistory {
    self.roomHistory = [DYRoomHistoryModel getAll];
    [self.roomComboBox reloadData];
}

- (void)reset {
    
}

- (IBAction)playAction:(NSButton *)sender {
    [self.roomComboBox resignFirstResponder];
    NSInteger videoQuality = self.videoQualityButton.indexOfSelectedItem;
    [[NSUserDefaults standardUserDefaults] setInteger:videoQuality forKey:@"videoQuality"];
    NSString *room = [self.roomComboBox.stringValue stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (room.length == 0) {
        room = self.roomComboBox.placeholderString;
    }
    [self playWithRoomString:room];
}

- (void)playWithRoomString:(NSString *)room {
    DYRoomInfo *roomInfo = [[DYRoomInfo alloc] init];
    NSString *roomId = [roomInfo getRoomIdWithString:room];
    if (!roomId.length) {
        [self showError:@"无法获取房间ID信息"];
        return;
    }
    if (!roomInfo.showStatus) {
        [self showError:@"主播不在线"];
        return;
    }
    NSInteger videoQuality = self.videoQualityButton.indexOfSelectedItem;
    int rate = 0;
    switch (videoQuality) {
        case 2:
            rate = 1;
            break;
        case 1:
            rate = 2;
            break;
        default:
            break;
    }
    if (![roomInfo getInfoWithRoomId:roomId rate:rate]) {
        [self showError:@"无法获取房间信息"];
        return;
    }
    [DYRoomHistoryModel saveRoomId:roomInfo.roomId withNickname:roomInfo.nickName];
    [self reloadHistory];

    NSWindowController *playerWindowController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"PlayerWindowController"];
    [playerWindowController.window center];
    [playerWindowController.window makeKeyAndOrderFront:nil];
    [playerWindowController.window setDelegate:self];
    self.playerWindowController = playerWindowController;
    PlayerViewController *playerViewController = (PlayerViewController *)playerWindowController.contentViewController;
    [playerViewController loadPlayerWithInfo:roomInfo];
    self.playerViewController = playerViewController;
    self.playingActivity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityIdleDisplaySleepDisabled reason:@"playing video"];
    [self.view.window performClose:nil];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
    [resizingTimer invalidate];
    resizingTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(resumePlay) userInfo:nil repeats:NO];
    [self.playerViewController.glView setPause:YES];
    return frameSize;
}

- (void)resumePlay {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        // call SetFrame to force opengl canvas resize
        NSView *videoView = self.playerViewController.glView;
        NSRect rect = videoView.frame;
        rect.size.width += 1;
        [videoView setFrame:rect];
        rect.size.width -= 1;
        [videoView setFrame:rect];
        [self.playerViewController.glView setPause:NO];
    });
}

- (void)showError:(NSString *)string {
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:string];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:[self.view window] completionHandler:nil];
}

- (void)windowWillClose:(NSNotification *)notification{
    [self.playerViewController destroyPlayer];
    self.playerWindowController = nil;
    [[NSProcessInfo processInfo] endActivity:self.playingActivity];
    [self reset];
    [self.view.window makeKeyAndOrderFront:nil];
}

@end
