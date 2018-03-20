//
//  NSDate+Datestring.h
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <Foundation/Foundation.h>

@interface NSDate (Datestring)
//当前日期转字符串
+(NSString *)allString;
//秒数转字符串日期
+(NSString *)TimetoStringWithdate:(unsigned int)time WithType:(NSString *)type;
//年月日转秒数
+(NSTimeInterval )TodayToSencond;
//字符串转NSDate
+(NSDate *)NSDatefromDateString:(NSString *)datestring WithType:(NSString *)type;
//日期转字符串
+(NSString *)StringformNSDate:(NSDate *)date WithType:(NSString *)type;
+(NSTimeInterval )SecondFromString:(NSString *)timeStr WithType:(NSString *)type;
+(NSTimeInterval )now;
+(NSString *)allStringWithType:(NSString *)type;
@end
