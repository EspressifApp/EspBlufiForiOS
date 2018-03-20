//
//  NSTimer+timerBlock.h
//  ZZCircleViewDemo
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <Foundation/Foundation.h>

@interface NSTimer (timerBlock)

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                         block:(void(^)())block
                                       repeats:(BOOL)repeats;

@end
