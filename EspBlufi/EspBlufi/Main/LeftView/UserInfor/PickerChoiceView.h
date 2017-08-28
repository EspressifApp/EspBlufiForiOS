//
//  PickerChoiceView.h
//  TFPickerView
//
//  Created by TF_man on 16/5/11.
//  Copyright © 2016年 tituanwang. All rights reserved.
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
