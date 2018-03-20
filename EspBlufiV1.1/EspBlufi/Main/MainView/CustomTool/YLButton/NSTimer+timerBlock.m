//
//  NSTimer+timerBlock.m
//  ZZCircleViewDemo
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import "NSTimer+timerBlock.h"

@implementation NSTimer (timerBlock)

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void (^)())block repeats:(BOOL)repeats {
    return [self scheduledTimerWithTimeInterval:interval target:self selector:@selector(blockInvoke:) userInfo:[block copy] repeats:repeats];
}

+ (void)blockInvoke:(NSTimer *)timer {
    void (^ block)() = timer.userInfo;
    if (block) {
        block();
    }
}

@end
