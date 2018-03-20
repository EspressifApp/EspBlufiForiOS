//
//  PickerChoiceView.h
//  TFPickerView
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <UIKit/UIKit.h>

@protocol TFPickerDelegate <NSObject>

@optional
- (void)PickerSelectorIndixString:(NSString *)str;
-(void)PickerSelectorCancel;

@end

typedef NS_ENUM(NSInteger, ARRAYTYPE) {
    GenderArray,
    alldateArray,
    DeteArray,
    Tempmmol_L,
    Tempmg_dL,
    MeasureModeArray,
    tempdate,
    ASICClock,
    OSR,
    ILED,
    GainTrim,
    MeasureInterval,
    Meal,
    Exercise,
    Insulin,
    DeviceMode,
    Security,
    channel,
    max_connection,
    
};

@interface PickerChoiceView : UIView

@property (nonatomic, assign) ARRAYTYPE arrayType;

@property (nonatomic, strong) NSArray *customArr;

@property (nonatomic,strong)UILabel *selectLb;

@property(nonatomic,strong)NSMutableArray *dateArray;

@property (nonatomic,assign)id<TFPickerDelegate>delegate;

@end
