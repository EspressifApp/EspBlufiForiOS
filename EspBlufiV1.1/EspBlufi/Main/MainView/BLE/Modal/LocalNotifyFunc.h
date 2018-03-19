//
//  LocalNotifyFunc.h
//  EspBlufi
//
//  Created by zhi weijian on 16/7/27.
//  Copyright © 2016年 zhi weijian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEViewController.h"

@interface LocalNotifyFunc : NSObject

+(void)playSound;
+(void)DeleteTempDefaultsAndCancelnotify;
//+(void)DeleteAllUserDefaultsAndCancelnotifyWithBlestate:(BleState)state;
+(void)PostWarningAndLocalNotifyWithUserinfor:(NSString *)infor WithLocalNotifyString:(NSString *)localstr SinceNow:(NSTimeInterval)time sound:(BOOL)sound repeat:(BOOL)repeat;
+(void)CancelLocalWarningWithUserinfor:(NSString *)infor;
+(void)localApplication:(NSString *)title sound:(BOOL)sound;
+(void)localWarningPerMinuteWithTitle:(NSString *)title WithUserinfor:(NSString *)infor sinceNow:(NSTimeInterval)time repeat:(BOOL)repeat;
+(void)EnablePlay;
+(void)DeleteDefaultsAndNotifyWithUserinfor:(NSString *)userinfor;
//+(void)DeleteUserDefault:(AlarmFlag)flag;
@end
