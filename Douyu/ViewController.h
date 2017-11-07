//
//  ViewController.h
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSTextField *roomTextField;
@property (weak) IBOutlet NSButton *playButton;
@property (weak) IBOutlet NSPopUpButton *videoQualityButton;

- (void)reset;

@end

