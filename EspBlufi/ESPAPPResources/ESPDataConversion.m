//
//  ESPDataConversion.m
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/12.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "ESPDataConversion.h"

#define SettingsFilter @"filterContent"
#define UseCustomFilter @"useCustomFilter"
#define DefaultFilter @"BLUFI"

@implementation ESPDataConversion

/**
 *  Defaults保存
 *
 *  @param value   要保存的数据
 *  @param key   关键字
 *  @return 保存结果
 */
+ (BOOL)fby_saveNSUserDefaults:(id)value withKey:(NSString *)key
{
    if((!value)||(!key)||key.length==0){
        NSLog(@"参数不能为空");
        return NO;
    }
    if(!([value isKindOfClass:[NSString class]]||[value isKindOfClass:[NSNumber class]]||[value isKindOfClass:[NSArray class]]||[value isKindOfClass:[NSDictionary class]])){
        NSLog(@"参数格式不对");
        return NO;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:value forKey:key];
    [defaults synchronize];
    return YES;
}

/**
 *  Defaults取出
 *
 *  @param key     关键字
 *  return  返回已保存的数据
 */
+ (id)fby_getNSUserDefaults:(NSString *)key{
    if(key==nil||key.length==0){
        NSLog(@"参数不能为空");
        return nil;
    }
    NSUserDefaults *version = [NSUserDefaults standardUserDefaults];
    id fbyVersion = [version objectForKey:key];
    [version synchronize];
    
    return fbyVersion;
}

+ (BOOL)saveBlufiScanFilter:(NSString *)filter {
    if (![self fby_saveNSUserDefaults:filter withKey:SettingsFilter]) {
        return NO;
    }
    [self fby_saveNSUserDefaults:@YES withKey:UseCustomFilter];
    return YES;
}

+ (NSString *)loadBlufiScanFilter {
    id custom = [self fby_getNSUserDefaults:UseCustomFilter];
    NSLog(@"loadBlufiScanFilter %@", custom);
    if (!custom || ![custom boolValue]) {
        return DefaultFilter;
    }
    return [self fby_getNSUserDefaults:SettingsFilter];
}

@end
