//
//  ViewController.h
//  Douyu
//
//  Created by Grayon on 2017/9/21.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak, nonatomic) IBOutlet NSButton *playButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *videoQualityButton;
@property (weak, nonatomic) IBOutlet NSComboBox *roomComboBox;

- (void)reset;

@end

