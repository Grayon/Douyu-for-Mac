
//
//  DanmuModel.m
//  DouyuTVDammu
//
//  Created by LuChen on 16/3/12.
//  Copyright © 2016年 Bad Chen. All rights reserved.
//

#import "DanmuModel.h"
#import "NSString+InfoGet.h"
#import "RegexKitLite.h"

@implementation DanmuModel

#define RGB(r,g,b,a)	[NSColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define ColorFromRGBHex(rgbValue)                                                                                                \
[NSColor colorWithRed:((float) ((rgbValue & 0xFF0000) >> 16)) / 255.0                                                        \
green:((float) ((rgbValue & 0xFF00) >> 8)) / 255.0                                                           \
blue:((float) (rgbValue & 0xFF)) / 255.0                                                                    \
alpha:1.0]

- (void)setModelFromStirng:(NSString *)string{

    _dataString = string;
    NSString *msg;
    
    switch (self.cellType) {
        case CellNewChatMessageType:
            {

                
                NSString *nickPattern = @"(?<=/nn@=).*?(?=/)";
                NSString *contentPattern = @"(?<=/txt@=).*?(?=/)";
                NSString *colorPattern = @"(?<=/col@=)\\d?(?=/)";
                NSString *ncPattern = @"(?<=/nc@=)\\d?(?=/)";
                NSString *name = [string componentsFirstMatchedByRegex:nickPattern];
                NSString *unReplaceTXT = [string componentsFirstMatchedByRegex:contentPattern];
                NSString *replaceTXT = [unReplaceTXT stringByReplacingOccurrencesOfRegex:@"@A" withString:@"@"];
                NSString *txt = [replaceTXT stringByReplacingOccurrencesOfRegex:@"@S" withString:@"/"];
                _nc = [[string componentsFirstMatchedByRegex:ncPattern] intValue];
                msg = txt;
                _nickname = name;
                int intColor = [[string componentsFirstMatchedByRegex:colorPattern] intValue];
                switch (intColor) {
                    case 1:
                        _color = ColorFromRGBHex(0xFF2D2D); //红
                        break;
                    case 2:
                        _color = ColorFromRGBHex(0x00ccff); //蓝
                        break;
                    case 3:
                        _color = ColorFromRGBHex(0x9AFF02);//绿
                        break;
                    case 4:
                        _color = [NSColor yellowColor];//黄
                        break;
                    case 5:
                        _color = ColorFromRGBHex(0xBF3EFF); //紫
                        break;
                    case 6:
                        _color = ColorFromRGBHex(0xFF60AF); //粉
                        break;
                    default:
                        _color = [NSColor whiteColor];
                        break;
                }
            }
            break;
        case CellNewGiftType:
            {

                NSString *nickPattern = @"(?<=nn@=).*?(?=/)";
                NSString *giftPattern = @"(?<=gfid@=).*?(?=/)";
                NSString *hitPattern = @"(?<=hits@=).*?(?=/)";
                
                NSString *name = [string componentsFirstMatchedByRegex:nickPattern];
                NSString *gift = [string componentsFirstMatchedByRegex:giftPattern];
                NSString *hits = [string componentsFirstMatchedByRegex:hitPattern];
                if (hits == NULL) {
                    hits = @"1";
                }
                NSString *giftName;
                NSURL *giftIconURL;
                for (NSDictionary *dic in self.gift) {
                    NSString *giftID = dic[@"id"];
                    if ([gift isEqualToString:giftID]) {
                        giftName = dic[@"name"];
                        giftIconURL = [NSURL URLWithString:dic[@"mobile_icon_v2"]];
                        break;
                    }
                }
                NSString *text = [NSString stringWithFormat:@"%@ 赠送给主播%@",name,giftName];
                
                msg = [NSString stringWithFormat:@"%@%@连击",text,hits];
                
            }
            break;
        case CellNewUserEnterType:
            {
                NSString *nickPattern = @"(?<=nn@=).*?(?=/)";
                NSString *name = [string componentsFirstMatchedByRegex:nickPattern];
                msg = [NSString stringWithFormat:@"%@ 进入了直播间",name];
            }
            break;
        case CellBanType:
            {
                NSString *nickPattern = @"(?<=snick@=).*?(?=/)";
                NSString *banedNamePattern = @"(?<=dnick@=).*?(?=/)";
                NSString *name = [string componentsFirstMatchedByRegex:nickPattern];
                NSString *banedName = [string componentsFirstMatchedByRegex:banedNamePattern];
                msg = [NSString stringWithFormat:@"管理员%@封禁了%@",name,banedName];
                
            }
            break;
        case CellDeserveType:
            {
            NSString *nickPattern = @"(?<=Snick@A=).*?(?=@)";
            NSString *levPattern = @"(?<=lev@=).*?(?=/)";
            NSString *hitPattern = @"(?<=hits@=).*?(?=/)";
            NSString *name = [[string componentsSeparatedByRegex:nickPattern]firstObject];
            NSInteger levle = [[[string componentsSeparatedByRegex:levPattern]firstObject]integerValue];
            NSString *hits = [[string componentsSeparatedByRegex:hitPattern]firstObject];
            NSString *deserve;

            switch (levle) {
                case 1:
                    deserve = @"初级酬勤";
                    break;
                case 2:
                    deserve = @"中级酬勤";
                    break;
                case 3:
                    deserve = @"高级酬勤";
                    break;
                default:
                    break;
            }
            msg = [NSString stringWithFormat:@"%@ 给主播赠送了%@%@连击",name,deserve,hits];
        }
        default:
            break;
    }
    _unColoredMsg = msg;
}



@end
