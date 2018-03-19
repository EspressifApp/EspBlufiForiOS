//
//  STLoopProgressView+BaseConfiguration.m
//  STLoopProgressView
//
//  Created by TangJR on 7/1/15.
//  Copyright (c) 2015 tangjr. All rights reserved.
//

#import "STLoopProgressView+BaseConfiguration.h"

#define DEGREES_TO_RADOANS(x) (M_PI * (x) / 180.0) // 将角度转为弧度

@implementation STLoopProgressView (BaseConfiguration)

+ (UIColor *)startColor {
    
    return [UIColor greenColor];
}

+ (UIColor *)centerColor {
    
    return [UIColor yellowColor];
}

+ (UIColor *)endColor {
    
    return [UIColor redColor];
}

+ (UIColor *)backgroundColor {
    
    return [UIColor colorWithRed:38 green:130 blue:213 alpha:0.5];
}

+ (CGFloat)lineWidth {
    
    //zwjLog(@"scan=%.f",[UIScreen mainScreen].bounds.size.width);
    //3.5
//    if ([UIScreen mainScreen].bounds.size.width<=320) {
//        return 27;
//    }else if ([UIScreen mainScreen].bounds.size.width>=414) //5.5
//    {
//        return 35;
//    }
//    return 32; //4.7
    
    return 20;
    
}

+ (CGFloat)startAngle {
    
    return DEGREES_TO_RADOANS(-360);
}

+ (CGFloat)endAngle {
    
    return DEGREES_TO_RADOANS(-0);
}

+ (STClockWiseType)clockWiseType {
    return STClockWiseNo;
}

@end
