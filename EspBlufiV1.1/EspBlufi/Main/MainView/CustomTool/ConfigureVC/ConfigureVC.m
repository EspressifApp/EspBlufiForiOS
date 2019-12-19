//
//  ConfigureVC.m
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import "ConfigureVC.h"
#import "UIColor+Hex.h"
#import "Prefix.pch"
#import "PickerChoiceView.h"
#import "HUDTips.h"
#import "OpmodeObject.h"
#import <SystemConfiguration/CaptiveNetwork.h>

#import "sendViewController.h"
#import <CoreLocation/CoreLocation.h>

#define ScreenW  [UIScreen mainScreen].bounds.size.width
#define ScreenH  [UIScreen mainScreen].bounds.size.height
#define offset 35
#define Height 40
#define labelFont 12

typedef enum
{
    DeviceModeIndex=0x00,
    SecurityIndex,
    ChannelIndex,
    Max_ConnectionIndex,
}SelectIndex;

typedef enum
{
    Openmode=0x00,
    Othermode,
}SoftPasswordMode;

@interface ConfigureVC ()<TFPickerDelegate,UITextFieldDelegate>

@property(nonatomic,assign)NSInteger selectindex;
@property(nonatomic,assign)UIButton *DeviceModeBtn;
@property(nonatomic,assign)UIButton *SoftAPSecurityBtn;
@property(nonatomic,assign)UIButton *SotAPChannelBtn;
@property(nonatomic,assign)UIButton *SoftAPSMax_ConnectBtn;

@property(nonatomic,strong)UIButton *okBtn;

@property(nonatomic,strong)UIView *softview;
@property(nonatomic,strong)UIView *softpasswordView;
@property(nonatomic,strong)UIView *wifiview;

@property(nonatomic,assign)Opmode displaymode;
@property(nonatomic,assign)SoftPasswordMode softpasswordmode;

@property(nonatomic,strong)UIScrollView *scrollview;
@property(nonatomic,strong)UITextField *currentTextfield;

//textField
@property(nonatomic,strong)UITextField *WifiSSidTextField;
@property(nonatomic,strong)UITextField *WifiPasswordTextField;
@property(nonatomic,strong)UITextField *SoftAPSSidTextfield;
@property(nonatomic,strong)UITextField *SoftAPPasswordTextfield;

@property(nonatomic,strong)CLLocationManager *locationManagerSystem;


@end

@implementation ConfigureVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImage *backimage=[UIImage imageNamed:@"back_normal"];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[backimage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:(UIBarButtonItemStylePlain) target:self action:@selector(didClickLeftBarBtnIem:)];
    
    self.navigationItem.title = @"配置";
    UIImage *sendImage=[UIImage imageNamed:@"send"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[sendImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:(UIBarButtonItemStylePlain) target:self action:@selector(didClickRightBarBtnIem:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillshow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillhidden:) name:UIKeyboardWillHideNotification object:nil];
    [self SetUI];
    //添加手势
    UITapGestureRecognizer *TapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.scrollview addGestureRecognizer:TapRecognizer];//关键语句，给self.view添加一个手势监测；
}
-(void)handleTapFrom:(UITapGestureRecognizer *)recognizer
{
    [self.scrollview endEditing:YES];
}
-(void)keyboardWillshow:(NSNotification *)notify
{
    //zwjLog(@"键盘显示");
    CGRect keyboardFrame = [notify.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardY = keyboardFrame.origin.y;
    CGFloat TextFieldY=[_currentTextfield convertRect:self.view.bounds toView:nil].origin.y+Height;
    CGFloat space=keyboardY-TextFieldY;
    if (space<0) {
        //zwjLog(@"移动");
        self.scrollview.frame=CGRectMake(0, space-Height-10, ScreenW, ScreenH);
    }
}
-(void)keyboardWillhidden:(NSNotification *)notify
{
    //zwjLog(@"键盘隐藏");
    self.scrollview.frame=CGRectMake(0, 0, ScreenW, ScreenH);
}
-(void)SetUI
{
    UIScrollView *scrollview=[[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, ScreenW, ScreenH)];
    [self.view addSubview:scrollview];
    self.scrollview=scrollview;
    
    CGFloat leftmargin=10;
   
    CGFloat labelW=120;
    CGFloat buttonW=[UIScreen mainScreen].bounds.size.width-labelW-leftmargin*2;
    
    //device mode
    UILabel *DeviceModeLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, offset, labelW, Height)];
    DeviceModeLabel.textAlignment=NSTextAlignmentCenter;
    DeviceModeLabel.text=@"Opmode:";
    DeviceModeLabel.textColor=[UIColor colorWithHexString:@"#666666"];
    [scrollview addSubview:DeviceModeLabel];
    
    UIButton *DeviceModeBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(DeviceModeLabel.frame)+leftmargin, offset, buttonW, Height)];
    [DeviceModeBtn setTitle:@"NULL" forState:UIControlStateNormal];
    DeviceModeBtn.titleLabel.font=[UIFont systemFontOfSize:20];
    DeviceModeBtn.layer.cornerRadius=DeviceModeBtn.bounds.size.height/2;
    DeviceModeBtn.layer.masksToBounds=YES;
    DeviceModeBtn.backgroundColor=[UIColor  colorWithHexString:@"#efefef"];
    [DeviceModeBtn setTitleColor:[UIColor colorWithHexString:@"#7aC4Eb"] forState:UIControlStateNormal];
    [DeviceModeBtn addTarget:self action:@selector(deviceModeBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.DeviceModeBtn=DeviceModeBtn;
    [scrollview addSubview:DeviceModeBtn];
    
    //softAPView ------------
    UIView *Softview=[[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(DeviceModeLabel.frame), [UIScreen mainScreen].bounds.size.width, Height*4+offset*4)];
    //Softview.backgroundColor=[UIColor redColor];
    [scrollview addSubview:Softview];
    self.softview=Softview;
    
    //SoftAPP Security
    
    UILabel *SoftAPSecurityLabel=[[UILabel alloc]initWithFrame:CGRectMake(0,offset, labelW, Height)];
    SoftAPSecurityLabel.textAlignment=NSTextAlignmentCenter;
    SoftAPSecurityLabel.text=@"Security:";
    SoftAPSecurityLabel.textColor=[UIColor colorWithHexString:@"#666666"];
    [Softview addSubview:SoftAPSecurityLabel];
    
    UIButton *SoftAPSecurityBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(SoftAPSecurityLabel.frame)+leftmargin,CGRectGetMinY(SoftAPSecurityLabel.frame), buttonW, Height)];
    [SoftAPSecurityBtn setTitle:@"OPEN" forState:UIControlStateNormal];
    SoftAPSecurityBtn.titleLabel.font=[UIFont systemFontOfSize:20];
    SoftAPSecurityBtn.layer.cornerRadius=DeviceModeBtn.bounds.size.height/2;
    SoftAPSecurityBtn.layer.masksToBounds=YES;
    SoftAPSecurityBtn.backgroundColor=[UIColor  colorWithHexString:@"#efefef"];
    [SoftAPSecurityBtn setTitleColor:[UIColor colorWithHexString:@"#7aC4Eb"] forState:UIControlStateNormal];
    [SoftAPSecurityBtn addTarget:self action:@selector(SoftAPSecurityBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.SoftAPSecurityBtn=SoftAPSecurityBtn;
    [Softview addSubview:SoftAPSecurityBtn];
    
    //SoftAP channel
    
    UILabel *SoftAPChannelLabel=[[UILabel alloc]initWithFrame:CGRectMake(0,CGRectGetMaxY(SoftAPSecurityLabel.frame)+offset, labelW, Height)];
    SoftAPChannelLabel.textAlignment=NSTextAlignmentCenter;
    SoftAPChannelLabel.text=@"Channel:";
    SoftAPChannelLabel.textColor=[UIColor colorWithHexString:@"#666666"];
    [Softview addSubview:SoftAPChannelLabel];
    
    UIButton *SoftAPchannelBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(SoftAPChannelLabel.frame)+leftmargin,CGRectGetMinY(SoftAPChannelLabel.frame), buttonW, Height)];
    [SoftAPchannelBtn setTitle:@"1" forState:UIControlStateNormal];
    SoftAPchannelBtn.titleLabel.font=[UIFont systemFontOfSize:20];
    SoftAPchannelBtn.layer.cornerRadius=DeviceModeBtn.bounds.size.height/2;
    SoftAPchannelBtn.layer.masksToBounds=YES;
    SoftAPchannelBtn.backgroundColor=[UIColor  colorWithHexString:@"#efefef"];
    [SoftAPchannelBtn setTitleColor:[UIColor colorWithHexString:@"#7aC4Eb"] forState:UIControlStateNormal];
    [SoftAPchannelBtn addTarget:self action:@selector(SoftAPchannelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.SotAPChannelBtn=SoftAPchannelBtn;
    [Softview addSubview:SoftAPchannelBtn];
    
    //SoftAP max connection
    
    UILabel *SoftAPMaxConnectLabel=[[UILabel alloc]initWithFrame:CGRectMake(0,CGRectGetMaxY(SoftAPChannelLabel.frame)+offset, labelW, Height)];
    SoftAPMaxConnectLabel.textAlignment=NSTextAlignmentCenter;
    SoftAPMaxConnectLabel.text=@"max connect:";
    [Softview addSubview:SoftAPMaxConnectLabel];
    SoftAPMaxConnectLabel.textColor=[UIColor colorWithHexString:@"#666666"];
    
    UIButton *SoftAPMaxConnectBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(SoftAPMaxConnectLabel.frame)+leftmargin,CGRectGetMinY(SoftAPMaxConnectLabel.frame), buttonW, Height)];
    [SoftAPMaxConnectBtn setTitle:@"1" forState:UIControlStateNormal];
    SoftAPMaxConnectBtn.titleLabel.font=[UIFont systemFontOfSize:20];
    SoftAPMaxConnectBtn.layer.cornerRadius=DeviceModeBtn.bounds.size.height/2;
    SoftAPMaxConnectBtn.layer.masksToBounds=YES;
    SoftAPMaxConnectBtn.backgroundColor=[UIColor  colorWithHexString:@"#efefef"];
    [SoftAPMaxConnectBtn setTitleColor:[UIColor colorWithHexString:@"#7aC4Eb"] forState:UIControlStateNormal];
    [SoftAPMaxConnectBtn addTarget:self action:@selector(SoftAPMaxConnectBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.SoftAPSMax_ConnectBtn=SoftAPMaxConnectBtn;
    [Softview addSubview:SoftAPMaxConnectBtn];
    
    
    //softAP ssid
    UITextField *SoftSsidTextField=[[UITextField alloc]initWithFrame:CGRectMake(leftmargin,CGRectGetMaxY(SoftAPMaxConnectBtn.frame)+offset, ScreenW-2*leftmargin, Height)];
    SoftSsidTextField.placeholder=@"SoftAP ssid";
    SoftSsidTextField.borderStyle=UITextBorderStyleNone;
    [Softview addSubview:SoftSsidTextField];
    SoftSsidTextField.delegate=self;
    SoftSsidTextField.returnKeyType=UIReturnKeyDone;
    SoftSsidTextField.textColor=[UIColor colorWithHexString:@"#666666"];
    self.SoftAPSSidTextfield=SoftSsidTextField;
    
    UIView *line=[[UIView alloc]initWithFrame:CGRectMake(0,self.SoftAPSSidTextfield.frame.size.height-2, self.SoftAPSSidTextfield.frame.size.width, 1)];
    line.backgroundColor=[UIColor lightGrayColor];
    [self.SoftAPSSidTextfield addSubview:line];
    
    //提示label
    UILabel *SoftAPssidlabel=[[UILabel alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMinY(SoftSsidTextField.frame)-20, 150, 20)];
    //wifissidlabel.backgroundColor=[UIColor lightGrayColor];
    SoftAPssidlabel.font=[UIFont systemFontOfSize:labelFont];
    SoftAPssidlabel.textColor=[UIColor colorWithHexString:@"#666666"];
    SoftAPssidlabel.text=@"SoftAP ssid:";
    [self.softview addSubview:SoftAPssidlabel];
    
    
    UIView *softpasswordView=[[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(Softview.frame), ScreenW, Height+offset)];
    //softpasswordView.backgroundColor=[UIColor greenColor];
    [scrollview addSubview:softpasswordView];
    self.softpasswordView=softpasswordView;
    
    
    //softAP password
    UITextField *SoftAPPasswordTextField=[[UITextField alloc]initWithFrame:CGRectMake(leftmargin,offset, ScreenW-2*leftmargin, Height)];
    SoftAPPasswordTextField.placeholder=@"SoftAP password";
    SoftAPPasswordTextField.borderStyle=UITextBorderStyleNone;
    [softpasswordView addSubview:SoftAPPasswordTextField];
    SoftAPPasswordTextField.delegate=self;
    SoftAPPasswordTextField.returnKeyType=UIReturnKeyDone;
    SoftAPPasswordTextField.secureTextEntry=YES;
    SoftAPPasswordTextField.textColor=[UIColor colorWithHexString:@"#666666"];
    //右侧按键
    UIButton *SoftAPbutton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, Height, Height)];
    //SoftAPbutton.backgroundColor=[UIColor redColor];
    [SoftAPbutton addTarget:self action:@selector(SoftAPpasswordhide) forControlEvents:UIControlEventTouchUpInside];
    [SoftAPbutton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [SoftAPbutton setImage:[UIImage imageNamed:@"password.png"] forState:UIControlStateNormal];
    SoftAPPasswordTextField.rightView=SoftAPbutton;
    SoftAPPasswordTextField.rightViewMode=UITextFieldViewModeAlways;
    self.SoftAPPasswordTextfield=SoftAPPasswordTextField;
    //线
    UIView *SoftAPPasswordline=[[UIView alloc]initWithFrame:CGRectMake(0,self.SoftAPPasswordTextfield.frame.size.height-2, self.SoftAPPasswordTextfield.frame.size.width, 1)];
    SoftAPPasswordline.backgroundColor=[UIColor lightGrayColor];
    [self.SoftAPPasswordTextfield addSubview:SoftAPPasswordline];
    
    
    //提示label
    UILabel *SoftAPpasswordlabel=[[UILabel alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMinY(SoftAPPasswordTextField.frame)-20, 150, 20)];
    //wifissidlabel.backgroundColor=[UIColor lightGrayColor];
    SoftAPpasswordlabel.font=[UIFont systemFontOfSize:labelFont];
    SoftAPpasswordlabel.textColor=[UIColor colorWithHexString:@"#666666"];
    SoftAPpasswordlabel.text=@"SoftAP password:";
    [self.softpasswordView addSubview:SoftAPpasswordlabel];
    
    
    //Wifi----------
    UIView *wifiView=[[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(softpasswordView.frame), ScreenW, Height*2+offset*2)];
    //wifiView.backgroundColor=[UIColor blueColor];
    [scrollview addSubview:wifiView];
    self.wifiview=wifiView;
    
    //Wifi ssid
    UITextField *WifiSsidTextField=[[UITextField alloc]initWithFrame:CGRectMake(leftmargin, offset, ScreenW-2*leftmargin, Height)];
    WifiSsidTextField.placeholder=@"Wifi ssid";
    WifiSsidTextField.borderStyle=UITextBorderStyleNone;
    [wifiView addSubview:WifiSsidTextField];
    WifiSsidTextField.delegate=self;
    WifiSsidTextField.returnKeyType=UIReturnKeyDone;
    WifiSsidTextField.textColor=[UIColor colorWithHexString:@"#666666"];
    self.WifiSSidTextField=WifiSsidTextField;
    if (![self getUserLocationAuth]) {
        _locationManagerSystem = [[CLLocationManager alloc]init];
        [_locationManagerSystem requestWhenInUseAuthorization];
    }
    WifiSsidTextField.text=[self getWifiName];
    
    //线
    UIView *WifiSsidline=[[UIView alloc]initWithFrame:CGRectMake(0,self.WifiSSidTextField.frame.size.height-2, self.WifiSSidTextField.frame.size.width, 1)];
    WifiSsidline.backgroundColor=[UIColor lightGrayColor];
    [self.WifiSSidTextField addSubview:WifiSsidline];
    
    UILabel *wifissidlabel=[[UILabel alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMinY(WifiSsidTextField.frame)-20, 150, 20)];
    //wifissidlabel.backgroundColor=[UIColor lightGrayColor];
    wifissidlabel.font=[UIFont systemFontOfSize:labelFont];
    wifissidlabel.textColor=[UIColor colorWithHexString:@"#666666"];
    wifissidlabel.text=@"wifi ssid:";
    [self.wifiview addSubview:wifissidlabel];
    
    //wifi password
    UITextField *WifiPasswordTextField=[[UITextField alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMaxY(WifiSsidTextField.frame)+offset, [UIScreen mainScreen].bounds.size.width-2*leftmargin, Height)];
    WifiPasswordTextField.placeholder=@"Wifi password";
    WifiPasswordTextField.borderStyle=UITextBorderStyleNone;
    [wifiView addSubview:WifiPasswordTextField];
    WifiPasswordTextField.delegate=self;
    WifiPasswordTextField.returnKeyType=UIReturnKeyDone;
    self.WifiPasswordTextField=WifiPasswordTextField;
    WifiPasswordTextField.returnKeyType=UIReturnKeyDone;
    WifiPasswordTextField.secureTextEntry=YES;
    
    //右侧按钮
    UIButton *Wifibutton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, Height, Height)];
    Wifibutton.tag=1;
    //button.backgroundColor=[UIColor redColor];
    [Wifibutton addTarget:self action:@selector(Wifipasswordhide) forControlEvents:UIControlEventTouchUpInside];
    [Wifibutton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [Wifibutton setImage:[UIImage imageNamed:@"password"] forState:UIControlStateNormal];
    WifiPasswordTextField.rightView=Wifibutton;
    WifiPasswordTextField.rightViewMode=UITextFieldViewModeAlways;
    
    //线
    UIView *WifiPasswordline=[[UIView alloc]initWithFrame:CGRectMake(0,self.WifiPasswordTextField.frame.size.height-2, self.WifiPasswordTextField.frame.size.width, 1)];
    WifiPasswordline.backgroundColor=[UIColor lightGrayColor];
    [self.WifiPasswordTextField addSubview:WifiPasswordline];

    UILabel *wifipasswordlabel=[[UILabel alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMinY(WifiPasswordTextField.frame)-20, 150, 20)];
    //wifissidlabel.backgroundColor=[UIColor lightGrayColor];
    wifipasswordlabel.font=[UIFont systemFontOfSize:labelFont];
    wifipasswordlabel.textColor=[UIColor colorWithHexString:@"#666666"];
    wifipasswordlabel.text=@"wifi password:";
    [self.wifiview addSubview:wifipasswordlabel];
    
    //配置按钮
    UIButton *btn=[[UIButton alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-buttonW)/2, CGRectGetMaxY(wifiView.frame)+offset, buttonW, Height)];
    btn.backgroundColor=[UIColor colorWithHexString:@"#7aC4Eb"];
    [btn setTitle:@"配置" forState:UIControlStateNormal];
    btn.layer.cornerRadius=btn.bounds.size.height/2;
    btn.layer.masksToBounds=YES;
    [btn addTarget:self action:@selector(okBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [scrollview addSubview:btn];
    self.okBtn=btn;
    
    
    self.softpasswordmode=Openmode;
    self.displaymode=NullOpmode;
    scrollview.contentSize=CGSizeMake(ScreenW, CGRectGetMaxY(btn.frame));
    scrollview.scrollEnabled=YES;
    
}
-(void)Wifipasswordhide
{
    self.WifiPasswordTextField.secureTextEntry=!self.WifiPasswordTextField.secureTextEntry;
    UIButton *btn=(UIButton *)self.WifiPasswordTextField.rightView;
    if (self.WifiPasswordTextField.secureTextEntry==YES) {
        [btn setImage:[UIImage imageNamed:@"password"] forState:UIControlStateNormal];
    }else
    {
        [btn setImage:[UIImage imageNamed:@"nopassword"] forState:UIControlStateNormal];
    }

}
-(void)SoftAPpasswordhide
{
    self.SoftAPPasswordTextfield.secureTextEntry=!self.SoftAPPasswordTextfield.secureTextEntry;
    UIButton *btn=(UIButton *)self.SoftAPPasswordTextfield.rightView;
    if (self.SoftAPPasswordTextfield.secureTextEntry==YES) {
        [btn setImage:[UIImage imageNamed:@"password"] forState:UIControlStateNormal];
    }else
    {
         [btn setImage:[UIImage imageNamed:@"nopassword"] forState:UIControlStateNormal];
    }
}

-(void)okBtnClick
{
    zwjLog(@"点击事件");
    
    if (self.displaymode==NullOpmode) {
       
        if ([self.delegate respondsToSelector:@selector(SetOpmode:Object:openmode:)]) {
            [self.delegate SetOpmode:NullOpmode Object:nil openmode:NO];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }else if (self.displaymode==STAOpmode)
    {
        if (self.WifiPasswordTextField.text.length>0 && self.WifiSSidTextField.text.length>0)
        {
            OpmodeObject *object=[[OpmodeObject alloc]init];
            object.WifiSSid=self.WifiSSidTextField.text;
            object.WifiPassword=self.WifiPasswordTextField.text;
            
            [self.delegate SetOpmode:STAOpmode Object:object openmode:NO];
            [self.navigationController popViewControllerAnimated:YES];
            
        }else
        {
            [HUDTips ShowLabelTipsToView:self.view WithText:@"参数不完整"];
        }
    
    }
    else if (self.displaymode==SoftAPOpmode)
    {
        
        if (self.softpasswordmode==Openmode) {
            if (self.SoftAPSSidTextfield.text.length<=0) {
                [HUDTips ShowLabelTipsToView:self.view WithText:@"参数不完整"];
                return;
            }
            
        }else
        {
            if (self.SoftAPSSidTextfield.text.length<=0 || self.SoftAPPasswordTextfield.text.length<=0) {
                [HUDTips ShowLabelTipsToView:self.view WithText:@"参数不完整"];
                return;
            }
        }
        
       
        OpmodeObject *object=[[OpmodeObject alloc]init];
        object.SoftAPSSid=self.SoftAPSSidTextfield.text;
        object.SoftAPPassword=self.SoftAPPasswordTextfield.text;
        object.channel=[self.SotAPChannelBtn.titleLabel.text integerValue];
        object.max_Connect=[self.SoftAPSMax_ConnectBtn.titleLabel.text integerValue];
        
        if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"OPEN"]) {
            object.Security=OPEN_Mode;
            
        }else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA_PSK"])
        {
            object.Security=WPA_PSK_Mode;
        }else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA2_PSK"])
        {
            object.Security=WPA2_PSK_Mode;
        }else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA_WPA2_PSK"])
        {
            object.Security=WPA_WPA2_PSK;
        }else
        {
            zwjLog(@"异常");
            return;
        }
        if ([self.delegate respondsToSelector:@selector(SetOpmode:Object:openmode:)]) {
            if (self.softpasswordmode==Openmode) {
                [self.delegate SetOpmode:SoftAPOpmode Object:object openmode:YES];
            }else
            {
                 [self.delegate SetOpmode:SoftAPOpmode Object:object openmode:NO];
            }
            
            [self.navigationController popViewControllerAnimated:YES];
        }
            
        
    
    }else if (self.displaymode==SoftAP_STAOpmode)
    {
        if (self.softpasswordmode==Openmode) {
            if (self.SoftAPSSidTextfield.text.length<=0 ||self.WifiPasswordTextField.text.length<=0 || self.WifiSSidTextField.text.length<=0) {
                [HUDTips ShowLabelTipsToView:self.view WithText:@"参数不完整"];
                return;
            }
            
        }else
        {
            if (self.SoftAPSSidTextfield.text.length<=0 || self.SoftAPPasswordTextfield.text.length<=0 ||self.WifiPasswordTextField.text.length<=0 || self.WifiSSidTextField.text.length<=0) {
                [HUDTips ShowLabelTipsToView:self.view WithText:@"参数不完整"];
                return;
            }
        }
        
        OpmodeObject *object=[[OpmodeObject alloc]init];
        object.SoftAPSSid=self.SoftAPSSidTextfield.text;
        object.SoftAPPassword=self.SoftAPPasswordTextfield.text;
        object.channel=[self.SotAPChannelBtn.titleLabel.text integerValue];
        object.max_Connect=[self.SoftAPSMax_ConnectBtn.titleLabel.text integerValue];
        
        if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"OPEN"]) {
            object.Security=OPEN_Mode;
            
        }else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA_PSK"])
        {
            object.Security=WPA_PSK_Mode;
        }else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA2_PSK"])
        {
            object.Security=WPA2_PSK_Mode;
        }else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA_WPA2_PSK"])
        {
            object.Security=WPA_WPA2_PSK;
        }else
        {
            zwjLog(@"异常");
            return;
        }
        object.WifiSSid=self.WifiSSidTextField.text;
        object.WifiPassword=self.WifiPasswordTextField.text;
        
        if ([self.delegate respondsToSelector:@selector(SetOpmode:Object:openmode:)]) {
            if (self.softpasswordmode==Openmode) {
                [self.delegate SetOpmode:SoftAP_STAOpmode Object:object openmode:YES];
            }else
            {
                [self.delegate SetOpmode:SoftAP_STAOpmode Object:object openmode:NO];
            }
            [self.navigationController popViewControllerAnimated:YES];
        }

    
    }else
    {
        zwjLog(@"异常");
    }
}


-(void)setDisplaymode:(Opmode)displaymode
{
    _displaymode=displaymode;
    
    switch (displaymode) {
        case NullOpmode:
        {
            self.softview.frame=CGRectMake(0,CGRectGetMaxY(self.DeviceModeBtn.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.softview.hidden=YES;
            self.softpasswordView.frame=CGRectMake(0,CGRectGetMaxY(self.softview.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.softpasswordView.hidden=YES;
            self.wifiview.frame=CGRectMake(0,CGRectGetMaxY(self.softpasswordView.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.wifiview.hidden=YES;
            self.okBtn.frame=CGRectMake(self.okBtn.frame.origin.x, CGRectGetMaxY(self.wifiview.frame)+offset, self.okBtn.bounds.size.width, self.okBtn.bounds.size.height);
             _scrollview.contentSize=CGSizeMake(ScreenW, CGRectGetMaxY(self.okBtn.frame)+100);
        }
            break;
        case STAOpmode:
        {
            self.softview.frame=CGRectMake(0,CGRectGetMaxY(self.DeviceModeBtn.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.softview.hidden=YES;
            
            self.softpasswordView.frame=CGRectMake(0,CGRectGetMaxY(self.softview.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.softpasswordView.hidden=YES;
            
            self.wifiview.frame=CGRectMake(0,CGRectGetMaxY(self.softpasswordView.frame), [UIScreen mainScreen].bounds.size.width, Height*2+offset*2);
            self.wifiview.hidden=NO;
            
            self.okBtn.frame=CGRectMake(self.okBtn.frame.origin.x, CGRectGetMaxY(self.wifiview.frame)+offset, self.okBtn.bounds.size.width, self.okBtn.bounds.size.height);
             _scrollview.contentSize=CGSizeMake(ScreenW, CGRectGetMaxY(self.okBtn.frame)+100);
        }
            break;
        case SoftAPOpmode:
        {
            self.softview.frame=CGRectMake(0,CGRectGetMaxY(self.DeviceModeBtn.frame), [UIScreen mainScreen].bounds.size.width, Height*4+offset*4);
            self.softview.hidden=NO;
            
            if (self.softpasswordmode==Openmode) {
                self.softpasswordView.frame=CGRectMake(0, CGRectGetMaxY(self.softview.frame), ScreenW, 0);
                self.softpasswordView.hidden=YES;
            }else
            {
                self.softpasswordView.frame=CGRectMake(0, CGRectGetMaxY(self.softview.frame), ScreenW, Height+offset);
                self.softpasswordView.hidden=NO;
            }
            
            self.wifiview.frame=CGRectMake(0,CGRectGetMaxY(self.softpasswordView.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.wifiview.hidden=YES;
            
            self.okBtn.frame=CGRectMake(self.okBtn.frame.origin.x, CGRectGetMaxY(self.wifiview.frame)+offset, self.okBtn.bounds.size.width, self.okBtn.bounds.size.height);
             _scrollview.contentSize=CGSizeMake(ScreenW, CGRectGetMaxY(self.okBtn.frame)+100);
        }
            break;
        case SoftAP_STAOpmode:
        {
            self.softview.frame=CGRectMake(0,CGRectGetMaxY(self.DeviceModeBtn.frame), [UIScreen mainScreen].bounds.size.width, Height*4+offset*4);
            self.softview.hidden=NO;
            
            if (self.softpasswordmode==Openmode) {
                self.softpasswordView.frame=CGRectMake(0, CGRectGetMaxY(self.softview.frame), ScreenW, 0);
                self.softpasswordView.hidden=YES;
            }else
            {
                self.softpasswordView.frame=CGRectMake(0, CGRectGetMaxY(self.softview.frame), ScreenW, Height+offset);
                self.softpasswordView.hidden=NO;
            }
            
            self.wifiview.frame=CGRectMake(0,CGRectGetMaxY(self.softpasswordView.frame), [UIScreen mainScreen].bounds.size.width, Height*2+offset*2);
            self.wifiview.hidden=NO;
            
            self.okBtn.frame=CGRectMake(self.okBtn.frame.origin.x, CGRectGetMaxY(self.wifiview.frame)+offset, self.okBtn.bounds.size.width, self.okBtn.bounds.size.height);
            _scrollview.contentSize=CGSizeMake(ScreenW, CGRectGetMaxY(self.okBtn.frame)+100);
        
        }
            break;
            
        default:
            break;
    }
    
}

-(void)SoftAPMaxConnectBtnClick
{
    [self.scrollview endEditing:YES];
    
    PickerChoiceView *picker = [[PickerChoiceView alloc]initWithFrame:self.view.bounds];
    picker.delegate = self;
    picker.arrayType=max_connection;
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:picker];
    self.selectindex=Max_ConnectionIndex;
}
-(void)SoftAPchannelBtnClick
{
    [self.scrollview endEditing:YES];
    
    PickerChoiceView *picker = [[PickerChoiceView alloc]initWithFrame:self.view.bounds];
    picker.delegate = self;
    picker.arrayType=channel;
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:picker];
    self.selectindex=ChannelIndex;

}
-(void)SoftAPSecurityBtnClick
{
    [self.scrollview endEditing:YES];
    
    PickerChoiceView *picker = [[PickerChoiceView alloc]initWithFrame:self.view.bounds];
    picker.delegate = self;
    picker.arrayType=Security;
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:picker];
    self.selectindex=SecurityIndex;
    
}
-(void)deviceModeBtnClick
{
    [self.scrollview endEditing:YES];
    
    PickerChoiceView *picker = [[PickerChoiceView alloc]initWithFrame:self.view.bounds];
    picker.delegate = self;
    picker.arrayType=DeviceMode;
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:picker];
    self.selectindex=DeviceModeIndex;
}
//Delegate
- (void)PickerSelectorIndixString:(NSString *)str
{
    if (self.selectindex==DeviceModeIndex) {
        [self.DeviceModeBtn setTitle:str forState:UIControlStateNormal];
        
        if ([str isEqualToString:@"NULL"]) {
            self.displaymode=NullOpmode;
            
        }else if ([str isEqualToString:@"STA"]) {
            self.displaymode=STAOpmode;
            
        }else if ([str isEqualToString:@"SoftAP"]) {
            self.displaymode=SoftAPOpmode;
            
        }else if ([str isEqualToString:@"SoftAP&STA"]) {
            self.displaymode=SoftAP_STAOpmode;
            
        }else
        {
            zwjLog(@"Error");
        }
        
    }else if (self.selectindex==SecurityIndex)
    {
        [self.SoftAPSecurityBtn setTitle:str forState:UIControlStateNormal];
        
        if ([str isEqualToString:@"OPEN"]) {
            self.softpasswordmode=Openmode;
        }else
        {
            self.softpasswordmode=Othermode;
        }
        self.displaymode=self.displaymode;
        
    }else if (self.selectindex==ChannelIndex)
    {
        [self.SotAPChannelBtn setTitle:str forState:UIControlStateNormal];
    }else if (self.selectindex==Max_ConnectionIndex)
    {
        [self.SoftAPSMax_ConnectBtn setTitle:str forState:UIControlStateNormal];
    }else
    {
        zwjLog(@"异常");
        
    }

}
- (void)didClickLeftBarBtnIem:(UIBarButtonItem *)sender
{
    //Log(@"didClickLeftBarBtnIem");
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)didClickRightBarBtnIem:(UIBarButtonItem *)sender
{
    sendViewController *svc = [[sendViewController alloc]init];
    [self.navigationController pushViewController:svc animated:YES];
}
//textField 代理
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
//textField 代理
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _currentTextfield=textField;
    return YES;
}
-(void)dealloc
{
    self.delegate=nil;
    zwjLog(@"%s",__func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    self.SoftAPSSidTextfield=nil;
    self.SoftAPSSidTextfield=nil;
    self.WifiSSidTextField=nil;
    self.WifiPasswordTextField=nil;
}
//获取wifi名称
- (NSString *)getWifiName

{
    
    NSString *wifiName = nil;
    
    CFArrayRef wifiInterfaces = CNCopySupportedInterfaces();
    
    if (!wifiInterfaces) {
        
        return nil;
        
    }
    
    NSArray *interfaces = (__bridge NSArray *)wifiInterfaces;
    
    for (NSString *interfaceName in interfaces) {
        
        CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo((__bridge CFStringRef)(interfaceName));
        
        if (dictRef) {
            
            NSDictionary *networkInfo = (__bridge NSDictionary *)dictRef;
            
            NSLog(@"network info -> %@", networkInfo);
            
            wifiName = [networkInfo objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID];
            
            CFRelease(dictRef);
        }
        
    }
    
    CFRelease(wifiInterfaces);
    
    return wifiName;
    
}

- (BOOL)getUserLocationAuth {
    BOOL result = NO;
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            break;
        case kCLAuthorizationStatusRestricted:
            break;
        case kCLAuthorizationStatusDenied:
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            result = YES;
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            result = YES;
            break;
            
        default:
            break;
    }
    return result;
}

@end
