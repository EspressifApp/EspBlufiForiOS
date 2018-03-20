//
//  LocalNotifyFunc.h
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
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
