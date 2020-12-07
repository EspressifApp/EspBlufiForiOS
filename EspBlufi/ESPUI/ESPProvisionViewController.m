//
//  ESPProvisionViewController.m
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/11.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "ESPProvisionViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "PickerChoiceView.h"
#import "HUDTips.h"

#define offset 35
#define Height 40
#define labelFont 12

typedef enum {
   OPEN_Mode        = 0x00,
   WEP_Mode         = 0x01,
   WPA_PSK_Mode     = 0x02,
   WPA2_PSK_Mode    = 0x03,
   WPA_WPA2_PSK     = 0X04,
} AuthenticationMode;

typedef enum
{
    DeviceModeIndex=0x00,
    SecurityIndex,
    ChannelIndex,
    Max_ConnectionIndex,
}SelectIndex;

typedef enum {
    Openmode=0x00,
    Othermode,
} SoftPasswordMode;

@interface ESPProvisionViewController ()<TFPickerDelegate, UITextFieldDelegate, CLLocationManagerDelegate>

@property(nonatomic,assign)NSInteger selectindex;
@property(nonatomic,strong)UIScrollView *scrollview;
@property(nonatomic,strong)UITextField *currentTextfield;

@property(nonatomic,strong)UIView *softview;
@property(nonatomic,strong)UIView *softpasswordView;
@property(nonatomic,strong)UIView *wifiview;

@property(nonatomic,assign)UIButton *DeviceModeBtn;
@property(nonatomic,assign)UIButton *SoftAPSecurityBtn;
@property(nonatomic,assign)UIButton *SotAPChannelBtn;
@property(nonatomic,assign)UIButton *SoftAPSMax_ConnectBtn;
@property(nonatomic,strong)UIButton *okBtn;

@property(nonatomic,strong)UITextField *SoftAPSSidTextfield;
@property(nonatomic,strong)UITextField *SoftAPPasswordTextfield;
@property(nonatomic,strong)UITextField *WifiSSidTextField;
@property(nonatomic,strong)UITextField *WifiPasswordTextField;

@property(nonatomic,assign)OpMode displaymode;
@property(nonatomic,assign)SoftPasswordMode softpasswordmode;

@property(nonatomic,strong)CLLocationManager *locationManagerSystem;

@end

@implementation ESPProvisionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = INTER_STR(@"EspBlufi-operation-provision");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillshow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillhidden:) name:UIKeyboardWillHideNotification object:nil];
    [self SetUI];
    UITapGestureRecognizer *TapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.scrollview addGestureRecognizer:TapRecognizer];
}

-(void)handleTapFrom:(UITapGestureRecognizer *)recognizer
{
    [self.scrollview endEditing:YES];
}

-(void)keyboardWillshow:(NSNotification *)notify
{
    CGRect keyboardFrame = [notify.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardY = keyboardFrame.origin.y;
    CGFloat TextFieldY=[_currentTextfield convertRect:self.view.bounds toView:nil].origin.y + Height;
    CGFloat space=keyboardY-TextFieldY;
    if (space<0) {
        self.scrollview.frame=CGRectMake(0, space - Height - 10, SCREEN_WIDTH, SCREEN_HEIGHT);
    }
}

-(void)keyboardWillhidden:(NSNotification *)notify
{
    self.scrollview.frame=CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
}

-(void)SetUI {
    UIScrollView *scrollview = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [self.view addSubview:scrollview];
    self.scrollview = scrollview;
    
    CGFloat leftmargin = 10;
   
    CGFloat labelW = 120;
    CGFloat buttonW = [UIScreen mainScreen].bounds.size.width - labelW - leftmargin * 2;
    
    //device mode
    UILabel *DeviceModeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, offset, labelW, Height)];
    DeviceModeLabel.textAlignment = NSTextAlignmentCenter;
    DeviceModeLabel.text = INTER_STR(@"EspBlufi-configure-opmode");
    DeviceModeLabel.textColor = APPTITLECOLOR;
    [scrollview addSubview:DeviceModeLabel];
    
    UIButton *DeviceModeBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(DeviceModeLabel.frame) + leftmargin, offset, buttonW, Height)];
    [DeviceModeBtn setTitle:@"NULL" forState:UIControlStateNormal];
    DeviceModeBtn.titleLabel.font = [UIFont systemFontOfSize:20];
    DeviceModeBtn.layer.cornerRadius = DeviceModeBtn.bounds.size.height/2;
    DeviceModeBtn.layer.masksToBounds = YES;
    DeviceModeBtn.backgroundColor = UICOLOR_RGBA(239, 239, 239, 1);
    [DeviceModeBtn setTitleColor:navColor forState:UIControlStateNormal];
    [DeviceModeBtn addTarget:self action:@selector(deviceModeBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.DeviceModeBtn = DeviceModeBtn;
    [scrollview addSubview:DeviceModeBtn];
    
    //softAPView ------------
    UIView *Softview = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(DeviceModeLabel.frame), [UIScreen mainScreen].bounds.size.width, Height * 4 + offset * 4)];
    //Softview.backgroundColor=[UIColor redColor];
    [scrollview addSubview:Softview];
    self.softview = Softview;
    
    //SoftAPP Security
    
    UILabel *SoftAPSecurityLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, offset, labelW, Height)];
    SoftAPSecurityLabel.textAlignment = NSTextAlignmentCenter;
    SoftAPSecurityLabel.text = INTER_STR(@"EspBlufi-configure-security");
    SoftAPSecurityLabel.textColor = APPTITLECOLOR;
    [Softview addSubview:SoftAPSecurityLabel];
    
    UIButton *SoftAPSecurityBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(SoftAPSecurityLabel.frame)+leftmargin,CGRectGetMinY(SoftAPSecurityLabel.frame), buttonW, Height)];
    [SoftAPSecurityBtn setTitle:@"OPEN" forState:UIControlStateNormal];
    SoftAPSecurityBtn.titleLabel.font = [UIFont systemFontOfSize:20];
    SoftAPSecurityBtn.layer.cornerRadius = DeviceModeBtn.bounds.size.height/2;
    SoftAPSecurityBtn.layer.masksToBounds = YES;
    SoftAPSecurityBtn.backgroundColor = UICOLOR_RGBA(239, 239, 239, 1);
    [SoftAPSecurityBtn setTitleColor:navColor forState:UIControlStateNormal];
    [SoftAPSecurityBtn addTarget:self action:@selector(SoftAPSecurityBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.SoftAPSecurityBtn = SoftAPSecurityBtn;
    [Softview addSubview:SoftAPSecurityBtn];
    
    //SoftAP channel
    
    UILabel *SoftAPChannelLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(SoftAPSecurityLabel.frame) + offset, labelW, Height)];
    SoftAPChannelLabel.textAlignment = NSTextAlignmentCenter;
    SoftAPChannelLabel.text = INTER_STR(@"EspBlufi-configure-channel");
    SoftAPChannelLabel.textColor = APPTITLECOLOR;
    [Softview addSubview:SoftAPChannelLabel];
    
    UIButton *SoftAPchannelBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(SoftAPChannelLabel.frame)+leftmargin,CGRectGetMinY(SoftAPChannelLabel.frame), buttonW, Height)];
    [SoftAPchannelBtn setTitle:@"1" forState:UIControlStateNormal];
    SoftAPchannelBtn.titleLabel.font = [UIFont systemFontOfSize:20];
    SoftAPchannelBtn.layer.cornerRadius = DeviceModeBtn.bounds.size.height/2;
    SoftAPchannelBtn.layer.masksToBounds = YES;
    SoftAPchannelBtn.backgroundColor = UICOLOR_RGBA(239, 239, 239, 1);
    [SoftAPchannelBtn setTitleColor:navColor forState:UIControlStateNormal];
    [SoftAPchannelBtn addTarget:self action:@selector(SoftAPchannelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.SotAPChannelBtn = SoftAPchannelBtn;
    [Softview addSubview:SoftAPchannelBtn];
    
    //SoftAP max connection
    
    UILabel *SoftAPMaxConnectLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,CGRectGetMaxY(SoftAPChannelLabel.frame) + offset, labelW, Height)];
    SoftAPMaxConnectLabel.textAlignment = NSTextAlignmentCenter;
    SoftAPMaxConnectLabel.text = INTER_STR(@"EspBlufi-configure-max-connect");
    [Softview addSubview:SoftAPMaxConnectLabel];
    SoftAPMaxConnectLabel.textColor = APPTITLECOLOR;
    
    UIButton *SoftAPMaxConnectBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(SoftAPMaxConnectLabel.frame)+leftmargin,CGRectGetMinY(SoftAPMaxConnectLabel.frame), buttonW, Height)];
    [SoftAPMaxConnectBtn setTitle:@"1" forState:UIControlStateNormal];
    SoftAPMaxConnectBtn.titleLabel.font = [UIFont systemFontOfSize:20];
    SoftAPMaxConnectBtn.layer.cornerRadius = DeviceModeBtn.bounds.size.height / 2;
    SoftAPMaxConnectBtn.layer.masksToBounds = YES;
    SoftAPMaxConnectBtn.backgroundColor = UICOLOR_RGBA(239, 239, 239, 1);
    [SoftAPMaxConnectBtn setTitleColor:navColor forState:UIControlStateNormal];
    [SoftAPMaxConnectBtn addTarget:self action:@selector(SoftAPMaxConnectBtnClick) forControlEvents:UIControlEventTouchUpInside];
    self.SoftAPSMax_ConnectBtn = SoftAPMaxConnectBtn;
    [Softview addSubview:SoftAPMaxConnectBtn];
    
    
    //softAP ssid
    UITextField *SoftSsidTextField = [[UITextField alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMaxY(SoftAPMaxConnectBtn.frame) + offset, SCREEN_WIDTH - 2 * leftmargin, Height)];
    SoftSsidTextField.placeholder = INTER_STR(@"EspBlufi-configure-softap-ssid");
    SoftSsidTextField.borderStyle = UITextBorderStyleNone;
    [Softview addSubview:SoftSsidTextField];
    SoftSsidTextField.delegate = self;
    SoftSsidTextField.returnKeyType = UIReturnKeyDone;
    SoftSsidTextField.textColor = APPTITLECOLOR;
    self.SoftAPSSidTextfield = SoftSsidTextField;
    
    UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0, self.SoftAPSSidTextfield.frame.size.height - 2, self.SoftAPSSidTextfield.frame.size.width, 1)];
    line.backgroundColor = [UIColor lightGrayColor];
    [self.SoftAPSSidTextfield addSubview:line];
    
    //提示label
    UILabel *SoftAPssidlabel = [[UILabel alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMinY(SoftSsidTextField.frame) - 20, 150, 20)];
    //wifissidlabel.backgroundColor=[UIColor lightGrayColor];
    SoftAPssidlabel.font = [UIFont systemFontOfSize:labelFont];
    SoftAPssidlabel.textColor = APPTITLECOLOR;
    SoftAPssidlabel.text = INTER_STR(@"EspBlufi-configure-softap-ssid");
    [self.softview addSubview:SoftAPssidlabel];
    
    
    UIView *softpasswordView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(Softview.frame), SCREEN_WIDTH, Height + offset)];
    //softpasswordView.backgroundColor=[UIColor greenColor];
    [scrollview addSubview:softpasswordView];
    self.softpasswordView = softpasswordView;
    
    
    //softAP password
    UITextField *SoftAPPasswordTextField = [[UITextField alloc]initWithFrame:CGRectMake(leftmargin, offset, SCREEN_WIDTH - 2 * leftmargin, Height)];
    SoftAPPasswordTextField.placeholder = INTER_STR(@"EspBlufi-configure-softap-password");
    SoftAPPasswordTextField.borderStyle = UITextBorderStyleNone;
    [softpasswordView addSubview:SoftAPPasswordTextField];
    SoftAPPasswordTextField.delegate = self;
    SoftAPPasswordTextField.returnKeyType = UIReturnKeyDone;
    SoftAPPasswordTextField.secureTextEntry = YES;
    SoftAPPasswordTextField.textColor = APPTITLECOLOR;
    //右侧按键
    UIButton *SoftAPbutton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, Height, Height)];
    //SoftAPbutton.backgroundColor=[UIColor redColor];
    [SoftAPbutton addTarget:self action:@selector(SoftAPpasswordhide) forControlEvents:UIControlEventTouchUpInside];
    [SoftAPbutton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [SoftAPbutton setImage:[UIImage imageNamed:@"password.png"] forState:UIControlStateNormal];
    SoftAPPasswordTextField.rightView = SoftAPbutton;
    SoftAPPasswordTextField.rightViewMode = UITextFieldViewModeAlways;
    self.SoftAPPasswordTextfield = SoftAPPasswordTextField;
    //线
    UIView *SoftAPPasswordline = [[UIView alloc]initWithFrame:CGRectMake(0, self.SoftAPPasswordTextfield.frame.size.height-2, self.SoftAPPasswordTextfield.frame.size.width, 1)];
    SoftAPPasswordline.backgroundColor = [UIColor lightGrayColor];
    [self.SoftAPPasswordTextfield addSubview:SoftAPPasswordline];
    
    
    //提示label
    UILabel *SoftAPpasswordlabel = [[UILabel alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMinY(SoftAPPasswordTextField.frame) - 20, 150, 20)];
    //wifissidlabel.backgroundColor=[UIColor lightGrayColor];
    SoftAPpasswordlabel.font = [UIFont systemFontOfSize:labelFont];
    SoftAPpasswordlabel.textColor = APPTITLECOLOR;
    SoftAPpasswordlabel.text = INTER_STR(@"EspBlufi-configure-softap-password");
    [self.softpasswordView addSubview:SoftAPpasswordlabel];
    
    
    //Wifi----------
    UIView *wifiView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(softpasswordView.frame), SCREEN_WIDTH, Height * 2 + offset * 2)];
    //wifiView.backgroundColor = [UIColor blueColor];
    [scrollview addSubview:wifiView];
    self.wifiview = wifiView;
    
    //Wifi ssid
    UITextField *WifiSsidTextField = [[UITextField alloc]initWithFrame:CGRectMake(leftmargin, offset, SCREEN_WIDTH - 2 * leftmargin, Height)];
    WifiSsidTextField.placeholder = INTER_STR(@"EspBlufi-configure-station-ssid");
    WifiSsidTextField.borderStyle = UITextBorderStyleNone;
    [wifiView addSubview:WifiSsidTextField];
    WifiSsidTextField.delegate = self;
    WifiSsidTextField.returnKeyType = UIReturnKeyDone;
    WifiSsidTextField.textColor = APPTITLECOLOR;
    self.WifiSSidTextField = WifiSsidTextField;
    if (![self getUserLocationAuth]) {
        _locationManagerSystem = [[CLLocationManager alloc]init];
        _locationManagerSystem.delegate = self;
        [_locationManagerSystem requestWhenInUseAuthorization];
    }
    WifiSsidTextField.text = [self getWifiName];
    
    //线
    UIView *WifiSsidline = [[UIView alloc]initWithFrame:CGRectMake(0,self.WifiSSidTextField.frame.size.height - 2, self.WifiSSidTextField.frame.size.width, 1)];
    WifiSsidline.backgroundColor = [UIColor lightGrayColor];
    [self.WifiSSidTextField addSubview:WifiSsidline];
    
    UILabel *wifissidlabel = [[UILabel alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMinY(WifiSsidTextField.frame) - 20, 150, 20)];
    //wifissidlabel.backgroundColor=[UIColor lightGrayColor];
    wifissidlabel.font = [UIFont systemFontOfSize:labelFont];
    wifissidlabel.textColor = APPTITLECOLOR;
    wifissidlabel.text = INTER_STR(@"EspBlufi-configure-station-ssid");
    [self.wifiview addSubview:wifissidlabel];
    
    //wifi password
    UITextField *WifiPasswordTextField = [[UITextField alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMaxY(WifiSsidTextField.frame) + offset, [UIScreen mainScreen].bounds.size.width - 2 * leftmargin, Height)];
    WifiPasswordTextField.placeholder = INTER_STR(@"EspBlufi-configure-station-password");
    WifiPasswordTextField.borderStyle = UITextBorderStyleNone;
    [wifiView addSubview:WifiPasswordTextField];
    WifiPasswordTextField.delegate = self;
    WifiPasswordTextField.returnKeyType = UIReturnKeyDone;
    self.WifiPasswordTextField = WifiPasswordTextField;
    WifiPasswordTextField.returnKeyType = UIReturnKeyDone;
    WifiPasswordTextField.secureTextEntry = YES;
    
    //右侧按钮
    UIButton *Wifibutton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, Height, Height)];
    Wifibutton.tag = 1;
    //button.backgroundColor = [UIColor redColor];
    [Wifibutton addTarget:self action:@selector(Wifipasswordhide) forControlEvents:UIControlEventTouchUpInside];
    [Wifibutton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [Wifibutton setImage:[UIImage imageNamed:@"password"] forState:UIControlStateNormal];
    WifiPasswordTextField.rightView = Wifibutton;
    WifiPasswordTextField.rightViewMode = UITextFieldViewModeAlways;
    
    //线
    UIView *WifiPasswordline = [[UIView alloc]initWithFrame:CGRectMake(0,self.WifiPasswordTextField.frame.size.height - 2, self.WifiPasswordTextField.frame.size.width, 1)];
    WifiPasswordline.backgroundColor = [UIColor lightGrayColor];
    [self.WifiPasswordTextField addSubview:WifiPasswordline];

    UILabel *wifipasswordlabel = [[UILabel alloc]initWithFrame:CGRectMake(leftmargin, CGRectGetMinY(WifiPasswordTextField.frame) - 20, 150, 20)];
    //wifissidlabel.backgroundColor = [UIColor lightGrayColor];
    wifipasswordlabel.font = [UIFont systemFontOfSize:labelFont];
    wifipasswordlabel.textColor = APPTITLECOLOR;
    wifipasswordlabel.text = INTER_STR(@"EspBlufi-configure-station-password");
    [self.wifiview addSubview:wifipasswordlabel];
    
    //配置按钮
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-buttonW) / 2, CGRectGetMaxY(wifiView.frame) + offset, buttonW, Height)];
    btn.backgroundColor = navColor;
    [btn setTitle:INTER_STR(@"EspBlufi-configure") forState:UIControlStateNormal];
    btn.layer.cornerRadius = btn.bounds.size.height/2;
    btn.layer.masksToBounds = YES;
    [btn addTarget:self action:@selector(okBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [scrollview addSubview:btn];
    self.okBtn = btn;
    
    self.softpasswordmode = Openmode;
    self.displaymode = OpModeNull;
    scrollview.contentSize = CGSizeMake(SCREEN_WIDTH, CGRectGetMaxY(btn.frame));
    scrollview.scrollEnabled = YES;
    
}

-(void)okBtnClick {
    NSLog(@"点击事件");
    BlufiConfigureParams *params = [[BlufiConfigureParams alloc] init];
    if (self.displaymode == OpModeNull) {
        params.opMode = OpModeNull;
        if (self.paramsDelegate) {
            [self.paramsDelegate didSetParams:params];
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else if (self.displaymode == OpModeSta) {
        NSLog(@"%@,%@", self.WifiPasswordTextField.text, self.WifiSSidTextField.text);
        params.opMode = OpModeSta;
        params.staSsid = self.WifiSSidTextField.text;
        params.staPassword = self.WifiPasswordTextField.text;
        if (self.paramsDelegate) {
            [self.paramsDelegate didSetParams:params];
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else if (self.displaymode == OpModeSoftAP) {
        if (self.softpasswordmode != Openmode) {
            if (self.SoftAPSSidTextfield.text.length <= 0) {
                [HUDTips ShowLabelTipsToView:self.view WithText:INTER_STR(@"EspBlufi-configure-softAp")];
                return;
            }
        }
       
        params.opMode = OpModeSoftAP;
        params.softApSsid = self.SoftAPSSidTextfield.text;
        params.softApPassword = self.SoftAPPasswordTextfield.text;
        params.softApChannel = [self.SotAPChannelBtn.titleLabel.text integerValue];
        params.softApMaxConnection = [self.SoftAPSMax_ConnectBtn.titleLabel.text integerValue];
        if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"OPEN"]) {
            params.softApSecurity = SoftAPSecurityOpen;
        } else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA_PSK"]) {
            params.softApSecurity = SoftAPSecurityWPA;
        } else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA2_PSK"]) {
            params.softApSecurity  = SoftAPSecurityWPA2;
        } else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA_WPA2_PSK"]) {
            params.softApSecurity = SoftAPSecurityWPAWPA2;
        } else {
            NSLog(@"异常");
            return;
        }
        
        if (self.paramsDelegate) {
            [self.paramsDelegate didSetParams:params];
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else if (self.displaymode == OpModeStaSoftAP) {
        if (self.softpasswordmode != Openmode) {
            if (self.SoftAPPasswordTextfield.text.length <= 0) {
                [HUDTips ShowLabelTipsToView:self.view WithText:INTER_STR(@"EspBlufi-configure-softAp")];
                return;
            }
        }
        params.opMode = OpModeStaSoftAP;
        params.softApSsid = self.SoftAPSSidTextfield.text;
        params.softApPassword = self.SoftAPPasswordTextfield.text;
        params.softApChannel = [self.SotAPChannelBtn.titleLabel.text integerValue];
        params.softApMaxConnection = [self.SoftAPSMax_ConnectBtn.titleLabel.text integerValue];
        if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"OPEN"]) {
            params.softApSecurity = SoftAPSecurityOpen;
        } else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA_PSK"]) {
            params.softApSecurity = SoftAPSecurityWPA;
        } else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA2_PSK"]) {
            params.softApSecurity = SoftAPSecurityWPA2;
        } else if ([self.SoftAPSecurityBtn.titleLabel.text isEqualToString:@"WPA_WPA2_PSK"]) {
            params.softApSecurity = SoftAPSecurityWPAWPA2;
        } else {
            NSLog(@"异常");
            return;
        }
        
        params.staSsid = self.WifiSSidTextField.text;
        params.staPassword = self.WifiPasswordTextField.text;
        
        if (self.paramsDelegate) {
            [self.paramsDelegate didSetParams:params];
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        NSLog(@"异常");
    }
}

-(void)setDisplaymode:(OpMode)displaymode {
    self.WifiSSidTextField.text = [self getWifiName];
    _displaymode = displaymode;
    switch (displaymode) {
        case OpModeNull:
        {
            self.softview.frame = CGRectMake(0,CGRectGetMaxY(self.DeviceModeBtn.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.softview.hidden = YES;
            self.softpasswordView.frame = CGRectMake(0,CGRectGetMaxY(self.softview.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.softpasswordView.hidden = YES;
            self.wifiview.frame = CGRectMake(0,CGRectGetMaxY(self.softpasswordView.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.wifiview.hidden = YES;
            self.okBtn.frame = CGRectMake(self.okBtn.frame.origin.x, CGRectGetMaxY(self.wifiview.frame)+offset, self.okBtn.bounds.size.width, self.okBtn.bounds.size.height);
             _scrollview.contentSize = CGSizeMake(SCREEN_WIDTH, CGRectGetMaxY(self.okBtn.frame)+100);
        }
            break;
        case OpModeSta:
        {
            self.softview.frame = CGRectMake(0,CGRectGetMaxY(self.DeviceModeBtn.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.softview.hidden = YES;
            
            self.softpasswordView.frame = CGRectMake(0,CGRectGetMaxY(self.softview.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.softpasswordView.hidden = YES;
            
            self.wifiview.frame = CGRectMake(0,CGRectGetMaxY(self.softpasswordView.frame), [UIScreen mainScreen].bounds.size.width, Height * 2 + offset * 2);
            self.wifiview.hidden = NO;
            
            self.okBtn.frame = CGRectMake(self.okBtn.frame.origin.x, CGRectGetMaxY(self.wifiview.frame) + offset, self.okBtn.bounds.size.width, self.okBtn.bounds.size.height);
             _scrollview.contentSize = CGSizeMake(SCREEN_WIDTH, CGRectGetMaxY(self.okBtn.frame) + 100);
        }
            break;
        case OpModeSoftAP:
        {
            self.softview.frame = CGRectMake(0,CGRectGetMaxY(self.DeviceModeBtn.frame), [UIScreen mainScreen].bounds.size.width, Height * 4 + offset * 4);
            self.softview.hidden = NO;
            
            if (self.softpasswordmode == Openmode) {
                self.softpasswordView.frame = CGRectMake(0, CGRectGetMaxY(self.softview.frame), SCREEN_WIDTH, 0);
                self.softpasswordView.hidden = YES;
            } else {
                self.softpasswordView.frame = CGRectMake(0, CGRectGetMaxY(self.softview.frame), SCREEN_WIDTH, Height + offset);
                self.softpasswordView.hidden = NO;
            }
            self.wifiview.frame = CGRectMake(0,CGRectGetMaxY(self.softpasswordView.frame), [UIScreen mainScreen].bounds.size.width, 0);
            self.wifiview.hidden = YES;
            
            self.okBtn.frame = CGRectMake(self.okBtn.frame.origin.x, CGRectGetMaxY(self.wifiview.frame) + offset, self.okBtn.bounds.size.width, self.okBtn.bounds.size.height);
            _scrollview.contentSize = CGSizeMake(SCREEN_WIDTH, CGRectGetMaxY(self.okBtn.frame) + 100);
        }
            break;
        case OpModeStaSoftAP:
        {
            self.softview.frame = CGRectMake(0,CGRectGetMaxY(self.DeviceModeBtn.frame), [UIScreen mainScreen].bounds.size.width, Height * 4 + offset * 4);
            self.softview.hidden = NO;
            
            if (self.softpasswordmode == Openmode) {
                self.softpasswordView.frame = CGRectMake(0, CGRectGetMaxY(self.softview.frame), SCREEN_WIDTH, 0);
                self.softpasswordView.hidden = YES;
            } else {
                self.softpasswordView.frame = CGRectMake(0, CGRectGetMaxY(self.softview.frame), SCREEN_WIDTH, Height + offset);
                self.softpasswordView.hidden = NO;
            }
            self.wifiview.frame = CGRectMake(0,CGRectGetMaxY(self.softpasswordView.frame), [UIScreen mainScreen].bounds.size.width, Height * 2 + offset * 2);
            self.wifiview.hidden = NO;
            
            self.okBtn.frame = CGRectMake(self.okBtn.frame.origin.x, CGRectGetMaxY(self.wifiview.frame) + offset, self.okBtn.bounds.size.width, self.okBtn.bounds.size.height);
            _scrollview.contentSize = CGSizeMake(SCREEN_WIDTH, CGRectGetMaxY(self.okBtn.frame) + 100);
        
        }
            break;
            
        default:
            break;
    }
    
}

-(void)deviceModeBtnClick {
    [self.scrollview endEditing:YES];
    
    PickerChoiceView *picker = [[PickerChoiceView alloc]initWithFrame:self.view.bounds];
    picker.delegate = self;
    picker.arrayType = DeviceMode;
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:picker];
    self.selectindex = DeviceModeIndex;
}

-(void)SoftAPMaxConnectBtnClick {
    [self.scrollview endEditing:YES];
    
    PickerChoiceView *picker = [[PickerChoiceView alloc]initWithFrame:self.view.bounds];
    picker.delegate = self;
    picker.arrayType=max_connection;
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:picker];
    self.selectindex=Max_ConnectionIndex;
}

-(void)SoftAPchannelBtnClick {
    [self.scrollview endEditing:YES];
    
    PickerChoiceView *picker = [[PickerChoiceView alloc]initWithFrame:self.view.bounds];
    picker.delegate = self;
    picker.arrayType=channel;
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:picker];
    self.selectindex=ChannelIndex;
}

-(void)SoftAPSecurityBtnClick {
    [self.scrollview endEditing:YES];
    PickerChoiceView *picker = [[PickerChoiceView alloc]initWithFrame:self.view.bounds];
    picker.delegate = self;
    picker.arrayType=Security;
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:picker];
    self.selectindex=SecurityIndex;
}

-(void)SoftAPpasswordhide {
    self.SoftAPPasswordTextfield.secureTextEntry=!self.SoftAPPasswordTextfield.secureTextEntry;
    UIButton *btn = (UIButton *)self.SoftAPPasswordTextfield.rightView;
    if (self.SoftAPPasswordTextfield.secureTextEntry==YES) {
        [btn setImage:[UIImage imageNamed:@"password"] forState:UIControlStateNormal];
    } else {
         [btn setImage:[UIImage imageNamed:@"nopassword"] forState:UIControlStateNormal];
    }
}
-(void)Wifipasswordhide {
    self.WifiPasswordTextField.secureTextEntry=!self.WifiPasswordTextField.secureTextEntry;
    UIButton *btn = (UIButton *)self.WifiPasswordTextField.rightView;
    if (self.WifiPasswordTextField.secureTextEntry==YES) {
        [btn setImage:[UIImage imageNamed:@"password"] forState:UIControlStateNormal];
    } else {
        [btn setImage:[UIImage imageNamed:@"nopassword"] forState:UIControlStateNormal];
    }

}

//Delegate
- (void)PickerSelectorIndixString:(NSString *)str {
    if (self.selectindex==DeviceModeIndex) {
        [self.DeviceModeBtn setTitle:str forState:UIControlStateNormal];
        if ([str isEqualToString:@"NULL"]) {
            self.displaymode=OpModeNull;
        }else if ([str isEqualToString:@"STA"]) {
            self.displaymode=OpModeSta;
        }else if ([str isEqualToString:@"SoftAP"]) {
            self.displaymode=OpModeSoftAP;
        }else if ([str isEqualToString:@"SoftAP&STA"]) {
            self.displaymode=OpModeStaSoftAP;
        } else {
            NSLog(@"Error");
        }
    } else if (self.selectindex==SecurityIndex) {
        [self.SoftAPSecurityBtn setTitle:str forState:UIControlStateNormal];
        if ([str isEqualToString:@"OPEN"]) {
            self.softpasswordmode=Openmode;
        } else {
            self.softpasswordmode=Othermode;
        }
        self.displaymode=self.displaymode;
    } else if (self.selectindex==ChannelIndex) {
        [self.SotAPChannelBtn setTitle:str forState:UIControlStateNormal];
    } else if (self.selectindex==Max_ConnectionIndex) {
        [self.SoftAPSMax_ConnectBtn setTitle:str forState:UIControlStateNormal];
    } else {
        NSLog(@"异常");
    }
}

//textField 代理
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

//textField 代理
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    _currentTextfield=textField;
    return YES;
}

-(void)dealloc {
    NSLog(@"%s",__func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    self.SoftAPSSidTextfield=nil;
    self.SoftAPSSidTextfield=nil;
    self.WifiSSidTextField=nil;
    self.WifiPasswordTextField=nil;
}

//获取wifi名称
- (NSString *)getWifiName {
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

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    BOOL result = NO;
    switch (status) {
           case kCLAuthorizationStatusNotDetermined:
               break;
           case kCLAuthorizationStatusRestricted:
               break;
           case kCLAuthorizationStatusDenied:
                result = YES;
               break;
           case kCLAuthorizationStatusAuthorizedAlways:
               break;
           case kCLAuthorizationStatusAuthorizedWhenInUse:
               break;
               
           default:
               break;
       }
    if (result) {
         UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"EspBlufi-location-title", nil) message:NSLocalizedString(@"EspBlufi-location-content", nil) preferredStyle:UIAlertControllerStyleAlert];
         
         UIAlertAction *action1 = [UIAlertAction actionWithTitle:NSLocalizedString(@"EspBlufi-cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
         UIAlertAction *action2 = [UIAlertAction actionWithTitle:NSLocalizedString(@"EspBlufi-set", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
             [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
         }];
         [alert addAction:action1];
         [alert addAction:action2];
         [self presentViewController:alert animated:YES completion:nil];
    }
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
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
