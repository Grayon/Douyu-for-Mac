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

@interface ViewController ()<NSWindowDelegate>

@property (strong) NSWindowController *playerWindowController;
@property (weak) PlayerViewController *playerViewController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self.view.window center];
}

- (void)reset {
    self.playButton.enabled = YES;
    self.roomTextField.enabled = YES;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (IBAction)playAction:(NSButton *)sender {
    [self.roomTextField resignFirstResponder];
    NSString *room = [self.roomTextField.stringValue stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (room.length == 0) {
        room = self.roomTextField.placeholderString;
    }
    NSString *roomId = [DYRoomInfo getRoomIdWithString:room];
    if (!roomId.length) {
        [self showError:@"无法获取房间ID信息"];
        return;
    }
    DYRoomInfo *roomInfo = [[DYRoomInfo alloc] init];
    if (![roomInfo getInfoWithRoomId:roomId]) {
        [self showError:@"无法获取房间信息"];
        return;
    }

    if (!roomInfo.showStatus) {
        [self showError:@"主播不在线"];
        return;
    }
    self.playButton.enabled = NO;
    self.roomTextField.enabled = NO;
    
    NSWindowController *playerWindowController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"PlayerWindowController"];
    [playerWindowController.window center];
    [playerWindowController.window makeKeyAndOrderFront:nil];
    [playerWindowController.window setDelegate:self];
    self.playerWindowController = playerWindowController;
    PlayerViewController *playerViewController = (PlayerViewController *)playerWindowController.contentViewController;
    [playerViewController loadPlayerWithInfo:roomInfo];
    self.playerViewController = playerViewController;
    [self.view.window performClose:nil];
}

- (void)showError:(NSString *)string {
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:string];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:[self.view window] completionHandler:nil];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
    frameSize.width=frameSize.height*1.78;
    return frameSize;
}

- (void)windowWillClose:(NSNotification *)notification{
    [self.playerViewController destroyPlayer];
    self.playerWindowController = nil;
    [self reset];
    [self.view.window makeKeyAndOrderFront:nil];
}

@end
