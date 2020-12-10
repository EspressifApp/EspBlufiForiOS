//
//  PickerChoiceView.m
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/11.
//  Copyright © 2020 espressif. All rights reserved.
//

//屏幕宽和高
#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)

//RGB
#define RGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]

// 缩放比
#define kScale ([UIScreen mainScreen].bounds.size.width) / 375

#define hScale ([UIScreen mainScreen].bounds.size.height) / 500 //default 667

//字体大小
#define kfont 15

#import "PickerChoiceView.h"
#import "Masonry.h"

@interface PickerChoiceView ()<UIPickerViewDelegate,UIPickerViewDataSource>

@property (nonatomic,strong)UIView *bgV;

@property (nonatomic,strong)UIButton *cancelBtn;

@property (nonatomic,strong)UIButton *conpleteBtn;


@property (nonatomic,strong)UIPickerView *pickerV;

@property (nonatomic,strong)NSMutableArray *array;
@end

@implementation PickerChoiceView

- (instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        
        self.array = [NSMutableArray array];
        
        self.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        self.backgroundColor = RGBA(51, 51, 51, 0.8);
        
        self.bgV = [[UIView alloc]initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, 260*hScale)];
        
        self.bgV.backgroundColor=[UIColor whiteColor];

        [self addSubview:self.bgV];
        
        [self showAnimation];
        
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 53)];
        view.backgroundColor = navColor;
        [self.bgV addSubview:view];
        
        
        //取消
        self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.bgV addSubview:self.cancelBtn];
        [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
           
            make.top.mas_equalTo(0);
            make.left.mas_equalTo(15);
            make.width.mas_equalTo(50);
            make.height.mas_equalTo(54);
            //默认宽30 高44
        }];
        self.cancelBtn.titleLabel.font = [UIFont systemFontOfSize:kfont];
        [self.cancelBtn setTitle:INTER_STR(@"cancel") forState:UIControlStateNormal];
        
        [self.cancelBtn addTarget:self action:@selector(cancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        //完成
        self.conpleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.bgV addSubview:self.conpleteBtn];
        [self.conpleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.top.mas_equalTo(0);
            make.right.mas_equalTo(-15);
            make.width.mas_equalTo(50);
            make.height.mas_equalTo(54);
            
        }];
        self.conpleteBtn.titleLabel.font = [UIFont systemFontOfSize:kfont];
        [self.conpleteBtn setTitle:INTER_STR(@"ok") forState:UIControlStateNormal];
       
        [self.conpleteBtn addTarget:self action:@selector(completeBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self.conpleteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        //选择titi
        self.selectLb = [[UILabel alloc]init];
        self.selectLb.textColor=[UIColor whiteColor];
        [self.bgV addSubview:self.selectLb];
        [self.selectLb mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.centerX.mas_equalTo(self.bgV.mas_centerX).offset(0);
            make.centerY.mas_equalTo(self.conpleteBtn.mas_centerY).offset(0);
            
        }];
        self.selectLb.font = [UIFont systemFontOfSize:kfont];
        self.selectLb.textAlignment = NSTextAlignmentCenter;
        
        //线
        UIView *line = [[UIView alloc]init];
        [self.bgV addSubview:line];
        [line mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.top.mas_equalTo(self.cancelBtn.mas_bottom).offset(0);
            make.left.mas_equalTo(0);
            make.width.mas_equalTo(kScreenWidth);
            make.height.mas_equalTo(0.5);
            
        }];
        line.backgroundColor = RGBA(224, 224, 224, 1);
        
        //选择器
        self.pickerV = [[UIPickerView alloc]init];
        self.pickerV.backgroundColor = UICOLOR_RGBA(248, 248, 248, 1);
        self.pickerV.delegate = self;
        self.pickerV.dataSource = self;
        [self.bgV addSubview:self.pickerV];
        [self.pickerV mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.top.mas_equalTo(line.mas_bottom).offset(0);
            make.bottom.mas_equalTo(0);
            make.left.mas_equalTo(0);
            make.right.mas_equalTo(0);
            
        }];
    }
    return self;
}

- (void)setCustomArr:(NSArray *)customArr{
    
    _customArr = customArr;
    [self.array addObject:customArr];
    
}

- (void)setArrayType:(ARRAYTYPE)arrayType
{
    _arrayType = arrayType;
    switch (arrayType) {
        case GenderArray:
        {
            self.selectLb.text = NSLocalizedString(@"selectgender", nil);
            [self.array addObject:@[NSLocalizedString(@"man", nil),NSLocalizedString(@"woman", nil)]];
        }
            break;
        case alldateArray:
        {
            self.selectLb.text = NSLocalizedString(@"time", nil);
            [self creatAllDate];
        }
            break;
        
        case DeteArray:
        {
            self.selectLb.text =NSLocalizedString(@"selectbirthdate", nil);
            [self creatDate];
        }
            break;
        case tempdate:
        {
            self.selectLb.text =NSLocalizedString(@"selectbirthdate", nil);
            [self creatTempdate];
        }
            break;
        case Tempmmol_L:
            self.selectLb.text = NSLocalizedString(@"temperature", nil);
            [self CreatCTemp];
            break;
        case Tempmg_dL:
            self.selectLb.text = NSLocalizedString(@"temperature", nil);
            [self CreatFTemp];
            break;
        case MeasureModeArray:
            self.selectLb.text = NSLocalizedString(@"selectmeasuermode", nil);
            [self.array addObject:@[NSLocalizedString(@"standardmode", nil),NSLocalizedString(@"smartmode", nil)]];
            break;
        case ASICClock:
            [self CreatASICClock];
            break;
        case OSR:
            [self CreatOSR];
            break;
            
        case ILED:
            [self CreatILED];
            break;
        case GainTrim:
            [self CreatGainTrim];
            break;
        case MeasureInterval:
            [self CreatMeasureInterval];
            break;
        case Meal:
            [self CreatMeal];
            break;
        case Exercise:
            [self CreatExercise];
            break;
        case Insulin:
            [self CreatInsulin];
            break;
        case DeviceMode:
            [self CreatDeviceMode];
            break;
        case Security:
            [self CreatSecurity];
            break;
        case channel:
            [self CreatChannel];
            break;
        case max_connection:
            [self CreatMax_Connect];
            break;
        default:
            break;
    }
}
-(void)CreatSecurity
{
    NSArray *SecurityArray=@[@"OPEN",@"WPA_PSK",@"WPA2_PSK",@"WPA_WPA2_PSK"];
    [self.array addObject:SecurityArray];
    [self.pickerV selectRow:1 inComponent:0 animated:YES];

}
-(void)CreatChannel
{
    NSMutableArray *ChannelArray = [[NSMutableArray alloc] init];
    for (int i = 1; i <= 13 ; i++)
    {
        [ChannelArray addObject:[NSString stringWithFormat:@"%d",i]];
    }
    [self.array addObject:ChannelArray];

}
-(void)CreatMax_Connect
{
    NSMutableArray *ConnectArray = [[NSMutableArray alloc] init];
    for (int i = 1; i <= 4 ; i++)
    {
        [ConnectArray addObject:[NSString stringWithFormat:@"%d",i]];
    }
    [self.array addObject:ConnectArray];
    
}
-(void)CreatDeviceMode
{
    NSArray *DeviceModeArray=@[@"NULL",@"STA",@"SoftAP",@"SoftAP&STA"];
    [self.array addObject:DeviceModeArray];
    [self.pickerV selectRow:1 inComponent:0 animated:YES];
    
}
-(void)CreatInsulin
{
    NSMutableArray *temp1=[NSMutableArray array];
    for (NSInteger i=1; i<=30; i++) {
        float value=0.5*i;
        [temp1 addObject:[NSString stringWithFormat:@"%.1f",value]];
    }
    [self.array addObject:temp1];
    [self.pickerV selectRow:temp1.count/2 inComponent:0 animated:YES];
}

-(void)CreatMeal
{
    NSArray *MealArray=@[NSLocalizedString(@"small",nil),NSLocalizedString(@"medium",nil),NSLocalizedString(@"large",nil)];
    [self.array addObject:MealArray];
    [self.pickerV selectRow:1 inComponent:0 animated:YES];
}
-(void)CreatExercise
{
    
    NSArray *ExerciseArray=@[NSLocalizedString(@"weak", nil),NSLocalizedString(@"moderate", nil),NSLocalizedString(@"intense", nil)];
    [self.array addObject:ExerciseArray];
    [self.pickerV selectRow:1 inComponent:0 animated:YES];
}
-(void)CreatMeasureInterval
{
    NSMutableArray *temp1=[NSMutableArray array];
    for (NSInteger i=10; i<=300; i++) {
        [temp1 addObject:[NSString stringWithFormat:@"%ld",i]];
    }
    [self.array addObject:temp1];
    [self.pickerV selectRow:50 inComponent:0 animated:YES];
}

-(void)CreatASICClock
{
    NSMutableArray *temp1=[NSMutableArray array];
    for (NSInteger i=5; i<=10; i++) {
        [temp1 addObject:[NSString stringWithFormat:@"%ld",i]];
    }
    [self.array addObject:temp1];
    [self.pickerV selectRow:temp1.count/2 inComponent:0 animated:YES];
    
}

-(void)CreatGainTrim
{
    NSArray *temp1=@[@"0",@"1",@"2",@"3"];
    [self.array addObject:temp1];
    [self.pickerV selectRow:temp1.count/2 inComponent:0 animated:YES];
}

-(void)CreatOSR
{
    NSArray *temp1=@[@"256",@"512",@"1024",@"2048"];
    [self.array addObject:temp1];
    [self.pickerV selectRow:temp1.count/2 inComponent:0 animated:YES];
    
}

-(void)CreatILED
{
    NSMutableArray *temp1=[NSMutableArray array];
    for (NSInteger i=0; i<=31; i++) {
        [temp1 addObject:[NSString stringWithFormat:@"%ld",i]];
    }
    [self.array addObject:temp1];
    [self.pickerV selectRow:temp1.count/2 inComponent:0 animated:YES];
}

-(void)CreatCTemp
{
    NSMutableArray *temp1=[NSMutableArray array];
    for (NSInteger i=0; i<=22; i++) {
        [temp1 addObject:[NSString stringWithFormat:@"%ld",i]];
    }
    [self.array addObject:temp1];
    
    NSMutableArray *temp2=[NSMutableArray array];
    [temp2 addObject:[NSString stringWithFormat:@"."]];
    [self.array addObject:temp2];
    
    NSMutableArray *temp3=[NSMutableArray array];
    for (NSInteger i=0; i<10; i++) {
        [temp3 addObject:[NSString stringWithFormat:@"%ld",i]];
    }
    [self.array addObject:temp3];
    [self.pickerV selectRow:temp1.count/2 inComponent:0 animated:YES];
    [self.pickerV selectRow:temp3.count/2 inComponent:2 animated:YES];
}
-(void)CreatFTemp
{
    NSMutableArray *temp1=[NSMutableArray array];
    for (NSInteger i=0;i<=396; i++) {
        [temp1 addObject:[NSString stringWithFormat:@"%ld",i]];
    }
    [self.array addObject:temp1];
    
    NSMutableArray *temp2=[NSMutableArray array];
    [temp2 addObject:[NSString stringWithFormat:@"."]];
    [self.array addObject:temp2];
    
    NSMutableArray *temp3=[NSMutableArray array];
    for (NSInteger i=0; i<10; i++) {
        [temp3 addObject:[NSString stringWithFormat:@"%ld",i]];
    }
    [self.array addObject:temp3];
    [self.pickerV selectRow:temp1.count/2 inComponent:0 animated:YES];
    [self.pickerV selectRow:temp3.count/2 inComponent:2 animated:YES];
}

- (void)creatDate{
    
    
    NSMutableArray *yearArray = [[NSMutableArray alloc] init];
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    
    [formatter setDateFormat:@"yyyy"];
    NSString *currentYear = [NSString stringWithFormat:@"%@",[formatter stringFromDate:date]];
    [formatter setDateFormat:@"MM"];
    NSString *currentMonth = [NSString stringWithFormat:@"%ld",(long)[[formatter stringFromDate:date]integerValue]];
    [formatter setDateFormat:@"dd"];
    NSString *currentday = [NSString stringWithFormat:@"%ld",(long)[[formatter stringFromDate:date]integerValue]];
    
    
    for (int i = 1949; i <= [currentYear integerValue] ; i++)
    {
        [yearArray addObject:[NSString stringWithFormat:@"%d",i]];
    }
    [self.array addObject:yearArray];
    
    NSMutableArray *monthArray = [[NSMutableArray alloc]init];
    for (int i = 1; i < 13; i ++) {
        
        [monthArray addObject:[NSString stringWithFormat:@"%d",i]];
    }
    [self.array addObject:monthArray];
    
    NSMutableArray *daysArray = [[NSMutableArray alloc]init];
    for (int i = 1; i < 32; i ++) {
        
        [daysArray addObject:[NSString stringWithFormat:@"%d",i]];
    }
    [self.array addObject:daysArray];
    
    
    [self.pickerV selectRow:[yearArray indexOfObject:currentYear] inComponent:0 animated:YES];
    //[self.pickerV selectRow:[yearArray indexOfObject:@"2012"] inComponent:0 animated:YES];
    
   
    [self.pickerV selectRow:[monthArray indexOfObject:currentMonth] inComponent:1 animated:YES];
    //[self.pickerV selectRow:[monthArray indexOfObject:@"6"] inComponent:1 animated:YES];
    
    [self.pickerV selectRow:[daysArray indexOfObject:currentday] inComponent:2 animated:YES];
    //[self.pickerV selectRow:[daysArray indexOfObject:@"15"] inComponent:2 animated:YES];
    
}

-(void)creatTempdate
{
    [self.array addObject:self.dateArray];
    [self.pickerV selectRow:self.dateArray.count-1 inComponent:0 animated:YES];
    
}
- (void)creatAllDate{
    
    
    NSMutableArray *yearArray = [[NSMutableArray alloc] init];
    for (int i = 1970; i <= 2050 ; i++)
    {
        [yearArray addObject:[NSString stringWithFormat:@"%d",i]];
    }
    [self.array addObject:yearArray];
    
    NSMutableArray *monthArray = [[NSMutableArray alloc]init];
    for (int i = 1; i < 13; i ++) {
        
        [monthArray addObject:[NSString stringWithFormat:@"%d",i]];
    }
    [self.array addObject:monthArray];
    
    NSMutableArray *daysArray = [[NSMutableArray alloc]init];
    for (int i = 1; i < 32; i ++) {
        
        [daysArray addObject:[NSString stringWithFormat:@"%d",i]];
    }
    [self.array addObject:daysArray];
    
    NSMutableArray *hoursArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < 24; i ++) {
        
        [hoursArray addObject:[NSString stringWithFormat:@"%02d",i]];
    }
    [self.array addObject:hoursArray];
    
    NSMutableArray *MinArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < 60; i ++) {
        
        [MinArray addObject:[NSString stringWithFormat:@"%02d",i]];
    }
    [self.array addObject:MinArray];
    
    
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    
    [formatter setDateFormat:@"yyyy"];
    NSString *currentYear = [NSString stringWithFormat:@"%@",[formatter stringFromDate:date]];
    [self.pickerV selectRow:[yearArray indexOfObject:currentYear] inComponent:0 animated:YES];
    
    [formatter setDateFormat:@"MM"];
    NSString *currentMonth = [NSString stringWithFormat:@"%ld",(long)[[formatter stringFromDate:date]integerValue]];
    [self.pickerV selectRow:[monthArray indexOfObject:currentMonth] inComponent:1 animated:YES];
    
    
    [formatter setDateFormat:@"dd"];
    NSString *currentday = [NSString stringWithFormat:@"%ld",(long)[[formatter stringFromDate:date]integerValue]];
    [self.pickerV selectRow:[daysArray indexOfObject:currentday] inComponent:2 animated:YES];
    
    [formatter setDateFormat:@"HH"];
    NSString *currenthour = [NSString stringWithFormat:@"%ld",(long)[[formatter stringFromDate:date]integerValue]];
    NSUInteger index=[daysArray indexOfObject:currenthour]+1;
    if (index>=24) {
        index=0;
    }
    [self.pickerV selectRow:index inComponent:3 animated:YES];
    
    [formatter setDateFormat:@"mm"];
    NSString *currentmin = [NSString stringWithFormat:@"%ld",(long)[[formatter stringFromDate:date]integerValue]];
    NSUInteger index2=[MinArray indexOfObject:currentmin];
    if (index2>=60) {
        index2=0;
    }
    [self.pickerV selectRow:index2 inComponent:4 animated:YES];
    
}

#pragma mark-----UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    
    return self.array.count;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
 
    NSArray * arr = (NSArray *)[self.array objectAtIndex:component];
    if (self.arrayType == DeteArray) {
        
        return arr.count;
        
    }else{
        
        return arr.count;
    }
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    if (@available(iOS 14.0, *)) {
        ((UIView *)[pickerView.subviews objectAtIndex:0]).backgroundColor = [UIColor clearColor];
    } else {
        ((UIView *)[pickerView.subviews objectAtIndex:1]).backgroundColor = [UIColor lightGrayColor];
        ((UIView *)[pickerView.subviews objectAtIndex:2]).backgroundColor = [UIColor lightGrayColor];
    }
    
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    label.textColor = navColor;
    label.font = [UIFont boldSystemFontOfSize:15];
    return label;
    
    
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    
    NSArray *arr = (NSArray *)[self.array objectAtIndex:component];
    return [arr objectAtIndex:row % arr.count];
    
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
   
    if (self.arrayType == DeteArray) {
        
        return 60;
        
    }else if (self.arrayType == alldateArray)
    {
        return 40;
    }else if (self.arrayType==Security)
    {
        return 150;
    }
    else{
        
        return 110;
    }
    
}

#pragma mark-----点击方法

- (void)cancelBtnClick{
    
    [self hideAnimation];
   
    
}

- (void)completeBtnClick{
    
    NSString *fullStr = [NSString string];
    for (int i = 0; i < self.array.count; i++)
    {
        
        NSArray *arr = [self.array objectAtIndex:i];
        if (self.arrayType == DeteArray)
        {
            
            NSString *str = [arr objectAtIndex:[self.pickerV selectedRowInComponent:i]% arr.count];
            if (i==self.array.count-1)
            {
                fullStr = [fullStr stringByAppendingString:str];
            }
            else
            {
                fullStr = [fullStr stringByAppendingString:[NSString stringWithFormat:@"%@-",str]];
            }
            
        }
        else if (self.arrayType==alldateArray)
        {
            NSString *str = [arr objectAtIndex:[self.pickerV selectedRowInComponent:i]% arr.count];
            if (i==self.array.count-1) {
               fullStr = [fullStr stringByAppendingString:str];
            }
            else if (i==self.array.count-2) {
                fullStr = [fullStr stringByAppendingString:[NSString stringWithFormat:@"%@:",str]];
            }
            else if (i==self.array.count-3){
                fullStr = [fullStr stringByAppendingString:[NSString stringWithFormat:@"%@ ",str]];
            }else
            {
                fullStr = [fullStr stringByAppendingString:[NSString stringWithFormat:@"%@.",str]];
            }
            
        }
        else
        {
            
            NSString *str = [arr objectAtIndex:[self.pickerV selectedRowInComponent:i]];
            fullStr = [fullStr stringByAppendingString:str];
        }
        

    }
    if ([self.delegate respondsToSelector:@selector(PickerSelectorIndixString:)]) {
        [self.delegate PickerSelectorIndixString:fullStr];
    }
    
    [self hideAnimation];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    //[self hideAnimation];
    

}

//隐藏动画
- (void)hideAnimation{
    
    [UIView animateWithDuration:0.5 animations:^{
        
        CGRect frame = self.bgV.frame;
        frame.origin.y = kScreenHeight;
        self.bgV.frame = frame;
        
    } completion:^(BOOL finished) {
        //判断语句必须加,否则崩溃
        if([self.delegate respondsToSelector:@selector(PickerSelectorCancel)])
        {
            [self.delegate PickerSelectorCancel];
        }
        [self.bgV removeFromSuperview];
        [self removeFromSuperview];
        
    }];
    
}

//显示动画
- (void)showAnimation{
    
    [UIView animateWithDuration:0.5 animations:^{
        
        CGRect frame = self.bgV.frame;
        frame.origin.y = kScreenHeight-260*hScale;
        self.bgV.frame = frame;
    }];
    
}


@end
