//
//  NSDate+Datestring.m
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import "NSDate+Datestring.h"

@implementation NSDate (Datestring)

+(NSString *)allString
{
    NSDate *now=[NSDate date];
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *str=[formatter stringFromDate:now];
    return str;
}
+(NSString *)allStringWithType:(NSString *)type
{
    NSDate *now=[NSDate date];
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    [formatter setDateFormat:type];
    NSString *str=[formatter stringFromDate:now];
    return str;
}
+(NSString *)StringformNSDate:(NSDate *)date WithType:(NSString *)type
{
    
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    [formatter setDateFormat:type];
    NSString *str=[formatter stringFromDate:date];
    return str;
}

+(NSString *)TimetoStringWithdate:(unsigned int)time WithType:(NSString *)type
{
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    [formatter setDateFormat:type];
    NSTimeZone *localtimezone=[NSTimeZone systemTimeZone];
    NSInteger offset=[localtimezone secondsFromGMT];
    NSDate *date=[NSDate dateWithTimeIntervalSince1970:(time-offset)];
    //NSDate *date=[NSDate dateWithTimeIntervalSince1970:(time)];
    NSString *timeStr=[formatter stringFromDate:date];
    return timeStr;
}
//获取当前天日期
+(NSTimeInterval )TodayToSencond
{
    //获取当前天日期
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    NSDate *currday = [calendar dateFromComponents:components];
    NSTimeZone *zone=[NSTimeZone systemTimeZone];
    NSInteger offset=[zone secondsFromGMT];
    return  [currday timeIntervalSince1970]+offset;
    //return  [currday timeIntervalSince1970];
}
//加上了时区的偏移秒数
+(NSTimeInterval )now
{
    NSDate *now = [NSDate date];
    NSTimeZone *zone=[NSTimeZone systemTimeZone];
    NSInteger offset=[zone secondsFromGMT];
    return  [now timeIntervalSince1970]+offset;
}

+(NSDate *)NSDatefromDateString:(NSString *)datestring WithType:(NSString *)type
{
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    [formatter setDateFormat:type];
    NSDate *date=[formatter dateFromString:datestring];
    return date;
}

//加上了时区的偏移秒数
+(NSTimeInterval )SecondFromString:(NSString *)timeStr WithType:(NSString *)type
{
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    [formatter setDateFormat:type];
    NSDate *date=[formatter dateFromString:timeStr];
    NSTimeZone *zone=[NSTimeZone systemTimeZone];
    NSInteger offset=[zone secondsFromGMT];
    return  ([date timeIntervalSince1970]+offset);
    //return  ([date timeIntervalSince1970]);
}

@end
