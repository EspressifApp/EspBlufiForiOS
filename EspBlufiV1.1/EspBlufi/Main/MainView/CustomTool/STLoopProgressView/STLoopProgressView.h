//
//  STLoopProgressView.h
//  STLoopProgressView
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, STClockWiseType) {
    STClockWiseYes,
    STClockWiseNo
};

@interface STLoopProgressView : UIView

@property (assign, nonatomic) CGFloat persentage;
@property(nonatomic,assign)BOOL color;

@property (nonatomic, copy) void (^didSelectBlock)(STLoopProgressView *progressView);
@property (nonatomic, strong) UIView *centralView;
@end
