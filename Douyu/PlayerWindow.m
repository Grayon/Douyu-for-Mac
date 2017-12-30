//
//  PlayerWindow.m
//  Douyu
//
//  Created by Grayon on 2017/9/22.
//  Copyright © 2017年 Lanskaya. All rights reserved.
//

#import "PlayerWindow.h"
#import "PlayerViewController.h"
#import <Carbon/Carbon.h>

@interface PlayerWindow () {
    BOOL shiftKeyPressed;
}

@end

@implementation PlayerWindow

- (void)flagsChanged:(NSEvent *) event {
    shiftKeyPressed = ([event modifierFlags] & NSShiftKeyMask) != 0;
}

- (void)keyDown:(NSEvent*)event {
    PlayerViewController *vc = (PlayerViewController *)self.contentViewController;
    if(!vc.mpv){
        NSLog(@"MPV not exists");
        return;
    }
    
    switch( [event keyCode] ) {
        case 53:{ // Esc key
            [self toggleFullScreen:self];
            break;
        }
        case 3:{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUInteger flags = [[NSApp currentEvent] modifierFlags];
                if ((flags & NSCommandKeyMask)) {
                    [self toggleFullScreen:self]; // Command+F key to toggle fullscreen
                }
            });
            break;
        }
        case 9:{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (vc.barrageRenderer.launched) {
                    [vc.barrageRenderer stop];
                } else {
                    [vc.barrageRenderer start];
                }
                const char *args[] = {"show-text", vc.barrageRenderer.launched?"已开启弹幕":"已关闭弹幕" ,NULL};
                mpv_command_async(vc.mpv,0, args);
            });
            break;
        }
        case 17:{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.level == NSFloatingWindowLevel) {
                    [self setLevel:NSNormalWindowLevel];
                } else {
                    [self setLevel:NSFloatingWindowLevel];
                }
            });
            break;
        }
        default:{
            [self handleKeyboardEvnet:event keyDown:YES];
            break;
        }
    }
}

-(void)keyUp:(NSEvent*)event {
    [self flagsChanged:event];
    [self handleKeyboardEvnet:event keyDown:NO];
}

- (void)handleKeyboardEvnet:(NSEvent *)event keyDown:(BOOL)keyDown {
    PlayerViewController *vc = (PlayerViewController *)self.contentViewController;
    if(!vc.mpv){
        return;
    }
    const char *keyState = keyDown?"keydown":"keyup";
    NSString *str = [self stringByKeyEvent:event];
    const char *args[] = {keyState, [str UTF8String], NULL};
    mpv_command_async(vc.mpv, 0, args);
}

CFStringRef stringByKeyCode(CGKeyCode keyCode)
{
    TISInputSourceRef currentKeyboard = TISCopyInputSourceForLanguage(CFSTR("en-US"));
    CFDataRef layoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
    if(!layoutData){
        return NULL;
    }
    const UCKeyboardLayout *keyboardLayout =
    (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    
    UInt32 keysDown = 0;
    UniChar chars[4];
    UniCharCount realLength;
    
    UCKeyTranslate(keyboardLayout,
                   keyCode,
                   kUCKeyActionDisplay,
                   0,
                   LMGetKbdType(),
                   kUCKeyTranslateNoDeadKeysBit,
                   &keysDown,
                   sizeof(chars) / sizeof(chars[0]),
                   &realLength,
                   chars);
    CFRelease(currentKeyboard);
    
    return CFStringCreateWithCharacters(kCFAllocatorDefault, chars, 1);
}


- (NSString *)stringByKeyEvent:(NSEvent*)event
{
    NSString *str = @"";
    int cocoaModifiers = [event modifierFlags];
    if (cocoaModifiers & NSControlKeyMask)
        str = [str stringByAppendingString:@"Ctrl+"];
    if (cocoaModifiers & NSCommandKeyMask)
        str = [str stringByAppendingString:@"Meta+"];
    if (cocoaModifiers & NSAlternateKeyMask)
        str = [str stringByAppendingString:@"Alt+"];
    if (cocoaModifiers & NSShiftKeyMask)
        str = [str stringByAppendingString:@"Shift+"];
    
    NSString *keystr;
    
    CFStringRef keystr_ref = stringByKeyCode([event keyCode]);
    if(keystr_ref){
        keystr = (__bridge NSString *)keystr_ref;
    }else{
        // If can't get key data from UCKeyTranslate, just convert ascii code , this will get many key works
        int value = [event keyCode];
        keystr = [NSString stringWithFormat:@"%c",(char)value];
    }
    
    if(keystr){
        str = [str stringByAppendingString:keystr];
    }
    
    NSLog(@"[PlayerWindow] Key event: %@",str);
    return str;
}

@end
