//
//  PickerChoiceView.h
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/11.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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


NS_ASSUME_NONNULL_END
