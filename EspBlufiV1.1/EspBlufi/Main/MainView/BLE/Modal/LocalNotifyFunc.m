//
//  LocalNotifyFunc.m
//  EspBlufi
//
//  Created by zhi weijian on 16/7/27.
//  Copyright © 2016年 zhi weijian. All rights reserved.
//

#import "Prefix.pch"
#import "LocalNotifyFunc.h"
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>


static SystemSoundID shake_sound_male_id = 0;

BOOL play=NO;

@implementation LocalNotifyFunc
//播放提示音
+(void)playSound
{
    if (play) {
        return;
    }
    play=YES;
    AudioServicesDisposeSystemSoundID(shake_sound_male_id);
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Soundwarning" ofType:@"wav"];
    if (path) {
        //注册声音到系统
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path],&shake_sound_male_id);
        //AudioServicesPlaySystemSound(shake_sound_male_id);
    }
    AudioServicesPlaySystemSound(shake_sound_male_id);   //播放注册的声音，（此句代码，可以在本类中的任意位置调用，不限于本方法中）
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);   //让手机震动
    AudioServicesAddSystemSoundCompletion(shake_sound_male_id, NULL, NULL, &playFinished,  (__bridge void *)(self));
}

+(void)EnablePlay
{
    play=NO;
}
void playFinished()
{
     // 移除完成后执行的函数
    AudioServicesRemoveSystemSoundCompletion(shake_sound_male_id);
    // 根据ID释放自定义系统声音
    AudioServicesDisposeSystemSoundID(shake_sound_male_id);
    play=NO;

}
+(void)DeleteTempDefaultsAndCancelnotify
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HighTemp"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LowTemp"];
    [self CancelLocalWarningWithUserinfor:@"HighTemp"];
    [self CancelLocalWarningWithUserinfor:@"LowTemp"];
}
+(void)DeleteDefaultsAndNotifyWithUserinfor:(NSString *)userinfor
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:userinfor];
    
    [self CancelLocalWarningWithUserinfor:userinfor];
   

}
//+(void)DeleteUserDefault:(AlarmFlag)flag
//{
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%d",flag]];
//}

//+(void)DeleteAllUserDefaultsAndCancelnotifyWithBlestate:(BleState)state
//{
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%d",HighBGValueFlag]];//高温通知标志
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%d",LowBGValueFlag]]; //低温通知标志
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%d",batterylowFlag]];//电池电量低通知标志
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%d",phonebatterylowFlag]];//手机电量低通知标志
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%d",TooLowBGVauleFlag]];
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%d",BGRapidlyFallingFlag]];
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%d",BGFallingFlag]];
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%d",BGRapidlyRisingFlag]];
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%d",BGRisingFlag]];
//    
////    [self CancelLocalWarningWithUserinfor:@"HighTemp"];
////    [self CancelLocalWarningWithUserinfor:@"LowTemp"];
////    [self CancelLocalWarningWithUserinfor:@"batterylow"];
////    [self CancelLocalWarningWithUserinfor:@"phonebatterylow"];
//    
//    if (state!=BleStateReConnect) {
//        [self CancelLocalWarningWithUserinfor:@"ReconnectTimeout"];
//    }
//}
+(void)PostWarningAndLocalNotifyWithUserinfor:(NSString *)infor WithLocalNotifyString:(NSString *)localstr SinceNow:(NSTimeInterval)time sound:(BOOL)sound repeat:(BOOL)repeat
{
    //取消周期警告
    [self CancelLocalWarningWithUserinfor:infor];
    
    NSString *str=[[NSUserDefaults standardUserDefaults] objectForKey:infor];
    if (str) {
        //发送本地通知
        //[self localApplication:localstr sound:NO];
    }else
    {
        //添加周期警告
        [self localWarningPerMinuteWithTitle:localstr WithUserinfor:infor sinceNow:time repeat:repeat];
        //播放警告音
        if (sound) {
            [self playSound];
        }
        //发送本地通知
        //[self localApplication:localstr sound:YES];
    }
     //Log(@"周期性警告");
}
//取消周期性警告
+(void)CancelLocalWarningWithUserinfor:(NSString *)infor
{
    NSArray *localarray=[UIApplication sharedApplication].scheduledLocalNotifications;
    for (UILocalNotification *notify in localarray) {
        NSDictionary *userinfor=notify.userInfo;
        if (userinfor) {
            NSString *str=userinfor[@"key"];
            if ([str isEqualToString:infor]) {
                [[UIApplication sharedApplication] cancelLocalNotification:notify];
                //Log(@"取消周期性警告");
            }
        }
    }
}
//发送本地通知
+(void)localApplication:(NSString *)title sound:(BOOL)sound
{
    // 1.创建本地通知
    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    // 1.1.设置什么时间弹出
    //localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
    // 1.2.设置弹出的内容
    localNote.alertBody = title;
    // 1.3.设置锁屏状态下,显示的一个文字
    localNote.alertAction = NSLocalizedString(@"open", nil);
    // 1.4.显示启动图片
    // localNote.alertLaunchImage = @"123";
    // 1.5.是否显示alertAction的文字(默认是YES)
    localNote.hasAction = YES;
    // 1.6.设置音效
    if(sound){
        localNote.soundName = @"Soundwarning.wav";
    }
    //localNote.repeatInterval=NSCalendarUnitSecond;
    // 1.7.应用图标右上角的提醒数字
    //localNote.applicationIconBadgeNumber = 1;
    // 1.8.设置UserInfo来传递信息
    //localNote.userInfo = @{@"alertBody" : localNote.alertBody, @"applicationIconBadgeNumber" : @(localNote.applicationIconBadgeNumber)};
    // 2.调度通知
    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
    //Log(@"发送本地通知");
}
//周期性警告通知
+(void)localWarningPerMinuteWithTitle:(NSString *)title WithUserinfor:(NSString *)infor sinceNow:(NSTimeInterval)time repeat:(BOOL)repeat
{
    //mark time=0 在iOS10上失效
    // 1.创建本地通知
    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    if(!localNote) return;
    //设置时区
    localNote.timeZone = [NSTimeZone localTimeZone];
    //1.1.设置什么时间弹出
    localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:time];
    
    if (repeat) {
        //重复周期分钟
        localNote.repeatInterval=NSCalendarUnitMinute;
    }
    
    // 1.2.设置弹出的内容
    localNote.alertBody = title;
    // 1.3.设置锁屏状态下,显示的一个文字
    localNote.alertAction = NSLocalizedString(@"open", nil);
    // 1.5.是否显示alertAction的文字(默认是YES)
    localNote.hasAction = YES;
    // 1.6.设置音效
    localNote.soundName = @"Soundwarning.wav";

    // 1.8.设置UserInfo来传递信息
    localNote.userInfo = @{@"key" : infor};
    // 2.调度通知
    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
    
}

@end
