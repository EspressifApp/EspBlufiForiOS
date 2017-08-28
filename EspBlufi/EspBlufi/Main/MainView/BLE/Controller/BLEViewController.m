//
//  ViewController.m
//  
//
//  Created by zhi weijian on 16/4/23.
//  Copyright © 2016年 zhi weijian. All rights reserved.
//
#import "BLEViewController.h"



#import "UUID.h"
#import "BLEDevice.h"
#import "UIColor+Hex.h"
#import "PopView.h"
#import "NSDate+Datestring.h"
#import "BLEdataFunc.h"
#import "LocalNotifyFunc.h"
#import "Prefix.pch"
#import "STLoopProgressView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "HUDTips.h"
#import "ZZCircleProgress.h"
#import "ConfigureVC.h"

#import "BabyBluetooth.h"
#import "PacketCommand.h"
#import "OpmodeObject.h"
#import "RSAObject.h"
#import "DH_AES.h"

#define filterBLEname   @"BLUFI"
#define SCANTIME        20
#define ConnectTime     2*60
#define ReconnectTime   5*60
//指令超时时间
#define CommandBtnTimeout 30

#define ArcMargin   20

#define ConnectedDeviceKey  @"ConnectedDevice"
#define ConnectedDeviceNameKey  @"ConnectedDeviceName"

#define WIDTH   [UIScreen mainScreen].bounds.size.width
#define HEIGHT  [UIScreen mainScreen].bounds.size.height


typedef enum {
    ForegroundMode=0,
    backgroundMode,
}ActiveMode;

typedef enum {
    ReconnecttimeoutAction=0,
    ConnectingAction,
    DisconnectAction,
    DeviceoverAction,
    CancelreconnectAction,
    StartSensorAction,
    DisconnectBLE,
    ClearData,
}AlertActionState;


@interface BLEViewController ()<PopViewDelegate,ConfigVCDelegate>
{
    BabyBluetooth *baby;
   
}

@property(nonatomic,strong) CBCharacteristic *WriteCharacteristic;
//当前连接设备信息
@property(nonatomic,strong)BLEDevice *currentdevice;

//断开连接标志,判断是自动断开还是意外断开
@property(nonatomic,assign)BOOL APPCancelConnect;
//扫描周围蓝牙设备集合
@property(nonatomic,strong)NSMutableArray *BLEDeviceArray;
//蓝牙状态
@property(nonatomic,assign)BleState blestate;
//App 运行模式
@property(nonatomic,assign)ActiveMode activemode;
//停止和开始布尔值
@property (nonatomic, assign) BOOL paused;
//环形进度条的进度,注意初始化时清零
@property (nonatomic, assign) CGFloat localProgress;
//设置模型
@property (strong, nonatomic)  STLoopProgressView *colorview;

//连接超时定时器
@property(nonatomic,strong)NSTimer *ConnectTimeoutTimer;
//提示view
@property(nonatomic,strong)PopView *popview;
//滑动手势
@property (nonatomic, strong) UISwipeGestureRecognizer *leftSwipeGestureRecognizer;

@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;

@property(nonatomic,strong) UIView *ScanBleView;

@property(nonatomic,strong) UILabel *titlelabel;

@property(nonatomic,assign)uint8_t sequence;

@property(nonatomic,strong)UILabel *Opmodelabel;
@property(nonatomic,strong)UILabel *STAStatelabel;
@property(nonatomic,strong)UILabel *STACountlabel;
@property(nonatomic,strong)UIButton *ConfigBtn;

@property(nonatomic,strong)UILabel *BSSidSTAlabel;
@property(nonatomic,strong)UILabel *SSidSTAlabel;


@property(nonatomic,strong)RSAObject *rsaobject;

@property(nonatomic,strong)NSData *senddata;

@property(nonatomic,copy)NSData *Securtkey;


@end

@implementation BLEViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.barTintColor=[UIColor colorWithHexString:@"#7aC4Eb"];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.titleTextAttributes=@{NSForegroundColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont boldSystemFontOfSize:20]};
    self.navigationController.navigationBarHidden = YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
   
    
    //设置背景样式
    [self SetBacklayerWithColor:[UIColor colorWithHexString:@"#7aC4Eb"]];
    //扫描界面
    [self addScanBLEview];
    //导航栏按钮
    [self setupitems];
    //初始化蓝牙
    baby=[BabyBluetooth shareBabyBluetooth];
    //设置蓝牙代理
    [self BleDelegate];
    //扫描到的蓝牙设备集合
    NSMutableArray *array=[NSMutableArray array];
    self.BLEDeviceArray=array;
    //设置蓝牙状态,空闲状态
    self.blestate=BleStateIdle;
    //清断开连接标志
    self.APPCancelConnect=NO;
    self.sequence=0;
    
    self.ConfigBtn.hidden=NO;
    //设置label and button
    [self SetLabelAndBuuton];
    //添加手势
    //[self AddgestureRecognizer];
    //获取DH秘钥
    self.rsaobject=[DH_AES DHGenerateKey];
}
-(void)SetLabelAndBuuton
{
    CGFloat buttonH=30;
    CGFloat buttonW=150;
    CGFloat buttonX=(WIDTH-buttonW)/2;
    CGFloat labelY=HEIGHT/2+ArcMargin;
    CGFloat labelH=30;
    CGFloat offset=(HEIGHT/2-ArcMargin-5*labelH-buttonH)/7;
    UILabel *Opmodelabel=[[UILabel alloc]initWithFrame:CGRectMake(0, labelY+offset, WIDTH, labelH)];
    Opmodelabel.textAlignment=NSTextAlignmentCenter;
    //Opmodelabel.backgroundColor=[UIColor redColor];
    [self.view addSubview:Opmodelabel];
    self.Opmodelabel=Opmodelabel;
    
    UILabel *STAStatelabel=[[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(Opmodelabel.frame)+offset, WIDTH, labelH)];
    STAStatelabel.textAlignment=NSTextAlignmentCenter;
    //STAStatelabel.backgroundColor=[UIColor redColor];
    [self.view addSubview:STAStatelabel];
    self.STAStatelabel=STAStatelabel;
    
    UILabel *STACountlabel=[[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(STAStatelabel.frame)+offset, WIDTH, labelH)];
    //STACountlabel.backgroundColor=[UIColor redColor];
    STACountlabel.textAlignment=NSTextAlignmentCenter;
    [self.view addSubview:STACountlabel];
    self.STACountlabel=STACountlabel;
    
    UILabel *BSSidSTAlabel=[[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(STACountlabel.frame)+offset, WIDTH, labelH)];
    BSSidSTAlabel.textAlignment=NSTextAlignmentCenter;
    [self.view addSubview:BSSidSTAlabel];
    self.BSSidSTAlabel=BSSidSTAlabel;
    
    UILabel *SSidSTAlabel=[[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(BSSidSTAlabel.frame)+offset, WIDTH, labelH)];
    SSidSTAlabel.textAlignment=NSTextAlignmentCenter;
    [self.view addSubview:SSidSTAlabel];
    self.SSidSTAlabel=SSidSTAlabel;
    

    UIButton *btn=[[UIButton alloc]initWithFrame:CGRectMake(buttonX, CGRectGetMaxY(SSidSTAlabel.frame)+offset, buttonW, buttonH)];
    //btn.backgroundColor=[UIColor redColor];
    [btn setTitle:@"配置" forState:UIControlStateNormal];
    [btn setBackgroundColor:[UIColor colorWithHexString:@"#7aC4Eb"]];
    btn.layer.cornerRadius=btn.bounds.size.height/2;
    btn.layer.masksToBounds=YES;
    [btn addTarget:self action:@selector(ConfigBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    self.ConfigBtn=btn;
    self.ConfigBtn.hidden=YES;
    
    
}
-(void)ConfigBtnClick:(UIButton *)sender
{
    /*
     
    if (self.blestate==BleStateConnected) {
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetOpmode:SoftAPOpmode Sequence:self.sequence]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetSoftAPSsid:@"zwj" Sequence:self.sequence]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetSoftAPPassword:@"123456789" Sequence:self.sequence]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetAuthenticationforSoftAP:WPA_WPA2_PSK Sequence:self.sequence]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetChannelforSoftAP:3 Sequence:self.sequence]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetMaxConnectforSoftAP:2 Sequence:self.sequence]];
        
    }
     
     */

    zwjLog(@"跳转到配置界面");
    ConfigureVC *vc=[[ConfigureVC alloc]init];
    vc.view.backgroundColor=[UIColor whiteColor];
    self.navigationController.navigationBarHidden=NO;
    [self.navigationController pushViewController:vc animated:YES];
    vc.delegate=self;
    
}
//ConfigVC 代理
-(void)SetOpmode:(Opmode)mode Object:(OpmodeObject *)object openmode:(BOOL)open
{
    if(mode==NullOpmode){
        
        NSData *data=[PacketCommand SetOpmode:NullOpmode Sequence:self.sequence];
        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:data];
        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:[PacketCommand GetDeviceInforWithSequence:self.sequence]];
    }else if (mode==STAOpmode)
    {
        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:[PacketCommand SetOpmode:STAOpmode Sequence:self.sequence]];
        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:[PacketCommand SetStationSsid:object.WifiSSid Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:[PacketCommand SetStationPassword:object.WifiPassword Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:[PacketCommand ConnectToAPWithSequence:self.sequence]];
        
        
    }else if (mode==SoftAP_STAOpmode)
    {
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetOpmode:SoftAP_STAOpmode Sequence:self.sequence]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetSoftAPSsid:object.SoftAPSSid Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        if (!open) {
          [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetSoftAPPassword:object.SoftAPPassword Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        }
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetAuthenticationforSoftAP:object.Security Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetChannelforSoftAP:object.channel Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetMaxConnectforSoftAP:object.max_Connect Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:[PacketCommand SetStationSsid:object.WifiSSid Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:[PacketCommand SetStationPassword:object.WifiPassword Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:[PacketCommand ConnectToAPWithSequence:self.sequence]];
        
    }else if (mode==SoftAPOpmode)
    {
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetOpmode:SoftAPOpmode Sequence:self.sequence]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetSoftAPSsid:object.SoftAPSSid Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        if (!open) {
          [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetSoftAPPassword:object.SoftAPPassword Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        }
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetAuthenticationforSoftAP:object.Security Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetChannelforSoftAP:object.channel Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetMaxConnectforSoftAP:object.max_Connect Sequence:self.sequence Encrypt:YES WithKeyData:self.Securtkey]];
    }
}
- (void)SetBacklayerWithColor:(UIColor *)color
{
    CGFloat width=[UIScreen mainScreen].bounds.size.width;
    CAShapeLayer *layer2 = [CAShapeLayer layer];
    layer2.fillColor =color.CGColor;
    layer2.frame = CGRectMake(0, 0, width, [UIScreen mainScreen].bounds.size.height/2);
    layer2.shouldRasterize = YES;
    layer2.path = [self getLayerBezierPath].CGPath;
    [self.view.layer addSublayer:layer2];
}
- (UIBezierPath *)getLayerBezierPath {
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height =(NSInteger)([UIScreen mainScreen].bounds.size.height/2.0);
    CGFloat R = 10+pow(width, 2)/160.0f;
    CGPoint centerArc = CGPointMake(width/2.0f,height+20-R);
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0, 0)];
    [bezierPath addLineToPoint:CGPointMake(0, height)];
    [bezierPath addArcWithCenter:centerArc radius:R startAngle:acos(width/(2*R)) endAngle:(M_PI-acos(width/(2*R))) clockwise:YES];
    [bezierPath addLineToPoint:CGPointMake(width, height)];
    [bezierPath addLineToPoint:CGPointMake(width, 0)];
    [bezierPath closePath];
    return bezierPath;
}
-(void)addScanBLEview
{
    __weak typeof(self) weakself =self;
    self.paused = YES;
    
    float ScanBLEviewW=[UIScreen mainScreen].bounds.size.width*0.7;//
    float ScanBLEviewX=([UIScreen mainScreen].bounds.size.width-ScanBLEviewW)/2;
    float ScanBLEviewY=([UIScreen mainScreen].bounds.size.height/2+20-63-ScanBLEviewW)/2+63;
    
    UIView *ScanBLEview=[[UIView alloc]initWithFrame:CGRectMake(ScanBLEviewX, ScanBLEviewY, ScanBLEviewW, ScanBLEviewW)];
    //ScanBLEview.backgroundColor=[UIColor redColor];
    [self.view addSubview:ScanBLEview];
    self.ScanBleView=ScanBLEview;
    STLoopProgressView *colorview=[[STLoopProgressView alloc]initWithFrame:CGRectMake(0, 0, ScanBLEviewW, ScanBLEviewW)];
    
    self.colorview=colorview;
    colorview.persentage=0.5;
    _localProgress=0.5;
    [ScanBLEview addSubview:colorview];
    colorview.backgroundColor=[UIColor colorWithHexString:@"#dadada" alpha:0.5];
    
    CGFloat labelH=50.0;
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(colorview.frame.size.width*0.1+5, CGRectGetMidY(colorview.frame)-labelH/2, self.colorview.bounds.size.width*0.8-10, labelH)];
    textLabel.font=[UIFont systemFontOfSize:50];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.textColor = [UIColor whiteColor];
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.adjustsFontSizeToFitWidth=YES;
    [ScanBLEview addSubview:textLabel];
    self.colorview.centralView = textLabel;
    
    colorview.didSelectBlock = ^(STLoopProgressView *progressView){
       
        switch (weakself.blestate) {
            case BleStateIdle:
                //清除设备集合
                [weakself.BLEDeviceArray removeAllObjects];
                baby.scanForPeripherals().begin().stop(SCANTIME);
                weakself.blestate=BleStateScan;
                break;
            case BleStateScan:
                self.popview=[self PopScanViewWithTitle:NSLocalizedString(@"scaning", nil)];
                break;
            case BleStateCancelConnect:
                //清除设备集合
                [weakself.BLEDeviceArray removeAllObjects];
                baby.scanForPeripherals().begin().stop(SCANTIME);
                weakself.blestate=BleStateScan;
                break;
            case BleStateNoDevice:
                //清除设备集合
                [weakself.BLEDeviceArray removeAllObjects];
                baby.scanForPeripherals().begin().stop(SCANTIME);
                weakself.blestate=BleStateScan;
                break;
            case BleStateConnected:
                //连接状态下,断开选择View
                [weakself AlertactionViewWithTitle:NSLocalizedString(@"tips", nil) Message:[NSString stringWithFormat:@"%@ %@",self.currentdevice.name,NSLocalizedString(@"taptodisconnect", nil)] OkactionTitle:NSLocalizedString(@"bledisconnect", nil) CancelActionTitle:NSLocalizedString(@"cancel", nil) AlertActionState:DisconnectAction preferredStyle:UIAlertControllerStyleActionSheet];
                break;
            case BleStateDisconnect:
                //清除设备集合
                [weakself.BLEDeviceArray removeAllObjects];
                baby.scanForPeripherals().begin().stop(SCANTIME);
                weakself.blestate=BleStateScan;
                break;
            case BleStateConnecting:
                
                [weakself AlertactionViewWithTitle:NSLocalizedString(@"tips", nil) Message:NSLocalizedString(@"stopconnect", nil) OkactionTitle:NSLocalizedString(@"stopconnect", nil) CancelActionTitle:NSLocalizedString(@"cancel", nil) AlertActionState:ConnectingAction preferredStyle:UIAlertControllerStyleActionSheet];
                break;
            case BleStateReConnect:
                
                [weakself AlertactionViewWithTitle:NSLocalizedString(@"tips", nil) Message:[NSString stringWithFormat:@"%@ %@, %@",NSLocalizedString(@"reconnecting", nil),self.currentdevice.name,NSLocalizedString(@"taptocancel", nil)] OkactionTitle:NSLocalizedString(@"stopreconnect", nil) CancelActionTitle:NSLocalizedString(@"cancel", nil) AlertActionState:CancelreconnectAction preferredStyle:UIAlertControllerStyleActionSheet];
                break;
            case BleStateConnecttimeout:
                [weakself.BLEDeviceArray removeAllObjects];
                baby.scanForPeripherals().begin().stop(SCANTIME);
                weakself.blestate=BleStateScan;
                break;
            case BleStateReconnecttimeout:
                [weakself.BLEDeviceArray removeAllObjects];
                baby.scanForPeripherals().begin().stop(SCANTIME);
                weakself.blestate=BleStateScan;
                break;
            default:
                break;
        }
    };
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
    _localProgress=0.50;
}
-(void)AddgestureRecognizer
{
    self.leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:self.leftSwipeGestureRecognizer];
    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:self.rightSwipeGestureRecognizer];
}
- (void)handleSwipes:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
        zwjLog(@"向左滑动");
        
    }else if (sender.direction==UISwipeGestureRecognizerDirectionRight)
    {
        zwjLog(@"向右滑动");
    }
}
//设置导航栏按钮
-(void)setupitems
{
    UIButton *SlideBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    SlideBtn.frame = CGRectMake(10, 25, 45, 45);
    [SlideBtn setImage:[UIImage imageNamed:@"III"] forState:UIControlStateNormal];
    [SlideBtn addTarget:self action:@selector(leftBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    //SlideBtn.backgroundColor=[UIColor redColor];
    [self.view addSubview:SlideBtn];
    
    UIButton *MoreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    MoreBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-10-45, 25, 45, 45);
    [MoreBtn setImage:[UIImage imageNamed:@"point"] forState:UIControlStateNormal];
    [MoreBtn addTarget:self action:@selector(RightBtnClick) forControlEvents:UIControlEventTouchUpInside];
    //[backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:MoreBtn];
    
    UILabel *textlabel=[[UILabel alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-100)/2, 27, 100, 35)];
    textlabel.textAlignment=NSTextAlignmentCenter;
    textlabel.font=[UIFont boldSystemFontOfSize:16];
    textlabel.textColor=[UIColor whiteColor];
    textlabel.text=NSLocalizedString(@"NODetector", nil);
    self.titlelabel=textlabel;
    [self.view addSubview:textlabel];
}
-(void)RightBtnClick
{
//    if (self.blestate==BleStateConnected) {
//        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:[PacketCommand GetDeviceInforWithSequence:self.sequence]];
//    }
    /*
    CGPoint point = CGPointMake(1, 0);
    float QQviewW=170;
    float QQviewH=250;
    float QQviewX=[UIScreen mainScreen].bounds.size.width-QQviewW-10;
    float QQviewY=79;
    [PopViewLikeQQView configCustomPopViewWithFrame:CGRectMake(QQviewX, QQviewY, QQviewW, QQviewH) anchorPoint:point seletedRowForIndex:^(NSInteger index) {
       
            switch (index) {
                case 0:
                    break;
                case 1:
                    break;
               
                default:
                    break;
            }
        
    } animation:YES timeForCome:0.3 timeForGo:0.3];
     */
}
//添加本地通知观察者
-(void)AddNotificationObserver
{
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ReceivedAPPEnterforeground:) name:@"APP_Enter" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ReconnectTimeout) name:@"ReconnectTimeout" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ReceivedAPPEnterbackground) name:@"APP_background" object:nil];
}
//进入后台
-(void)ReceivedAPPEnterbackground
{
    self.activemode=backgroundMode;
}
//进入前台通知
-(void)ReceivedAPPEnterforeground:(NSNotification *)noti
{
    self.activemode=ForegroundMode;
}

//更新progressview
- (void)updateProgress:(NSTimer *)timer {
    if (!_paused) {
        _localProgress = ((int)((_localProgress * 100.0f) + 1.01) % 100) / 100.0f;
        [self.colorview setPersentage:_localProgress];
    }
}
//开始进度条
-(void)StartProgressViewWithTitle:(NSString *)title
{
    self.colorview.persentage=0;
    self.localProgress=0;
    UILabel *label= (UILabel *)self.colorview.centralView;
    label.text=title;
    self.paused=NO;
}
//停止进度条
-(void)StopProgressView
{
    _localProgress=0.5;
    self.colorview.persentage=0.5;
    self.paused=YES;
}
-(void)changeProgressViewWithColor:(BOOL)color
{
    self.colorview.color=color;
    [self.colorview setNeedsDisplay];
}
//设置进度条显示title,无动画
-(void)SetProgressViewTitle:(NSString *)Centraltitle
{
    UILabel *label= (UILabel *)self.colorview.centralView;
    label.text=Centraltitle;
}

//打开或关闭左侧菜单栏
- (void)leftBtnClick:(UIBarButtonItem *)sender {
//    //判断菜单展示状态
//    if ([MenuViewController getMenuViewController].isShowing ) {
//        //关闭菜单方法
//        [[MenuViewController getMenuViewController] hideLeftViewControlller];
//    }else{
//        //打开菜单方法
//        [[MenuViewController getMenuViewController] showLeftViewController];
//    }
    
}

/**
 *  蓝牙代理
 */
-(void)BleDelegate
{
    __weak typeof(baby) weakbaby = baby;
    __weak typeof(self) weakself =self;
    //判断手机蓝牙状态
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        //检测蓝牙状态
        if (central.state==CBCentralManagerStatePoweredOn) {
            //Log(@"蓝牙已打开");
            weakself.blestate=BleStatePowerOn;
            
            NSString *UUIDStr=[[NSUserDefaults standardUserDefaults] objectForKey:ConnectedDeviceKey];
            if (UUIDStr && AutoConnect) {
                CBPeripheral *peripheral=[weakbaby retrievePeripheralWithUUIDString:UUIDStr];
                [weakself connect:peripheral];
                weakself.blestate=BleStateConnecting;
                BLEDevice *device=[[BLEDevice alloc]init];
                device.Peripheral=peripheral;
                device.name=[[NSUserDefaults standardUserDefaults] objectForKey:ConnectedDeviceNameKey];
                weakself.currentdevice=device;
                
            }
        }
        if(central.state==CBCentralManagerStateUnsupported)
        {
            //Log(@"该设备不支持蓝牙BLE");
            weakself.blestate=BleStateUnknown;
        }
        if (central.state==CBCentralManagerStatePoweredOff) {
            //Log(@"蓝牙已关闭");
            weakself.blestate=BleStatePoweroff;
        }
    }];

    //搜索蓝牙
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        zwjLog(@"搜索到了设备:%@,%@",peripheral.name,advertisementData);
        //将扫描到的设备添加到数组中
        //NSString *serialnumber=[BLEdataFunc GetSerialNumber:advertisementData];
        //NSString *name=[NSString stringWithFormat:@"%@%@",peripheral.name,serialnumber];
        NSString *name=[NSString stringWithFormat:@"%@",peripheral.name];
        if (![BLEdataFunc isAleadyExist:name BLEDeviceArray:weakself.BLEDeviceArray])
        {
            BLEDevice *device=[[BLEDevice alloc]init];
            device.name=name;
            device.Peripheral=peripheral;
            [weakself.BLEDeviceArray addObject:device];
            
            if (weakself.popview) {
                weakself.popview.dataArray=weakself.BLEDeviceArray;
            }
            else if (!weakself.popview && weakself.BLEDeviceArray.count==1)
            {
                weakself.popview=[weakself PopScanViewWithTitle:NSLocalizedString(@"scaning", nil)];
            }
            
        }
    }];
    
    //设置扫描过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI)
     {
         if ([peripheralName hasPrefix:filterBLEname])
         {
             return YES;
         }
         return NO;
     }];
    
    //设置连接过滤器
    [baby setFilterOnConnectToPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        if ([peripheralName hasPrefix:filterBLEname]) {
            //isFirst=NO;
            //zwjLog(@"准备连接");
            weakself.blestate=BleStateConnecting;
            return YES;
        }
        return NO;
    }];
    
    //连接成功
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        zwjLog(@"设备：%@--连接成功",peripheral.name);
        //取消自动回连功能(连接成功后必须清除自动回连,否则会崩溃)
        [weakself AutoReconnectCancel:weakself.currentdevice.Peripheral];
        
        }];
    
    //设备连接失败
    [baby setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        zwjLog(@"设备：%@--连接失败",peripheral.name);
        //清除主动断开标志
        weakself.APPCancelConnect=NO;
        //[LocalNotifyFunc DeleteAllUserDefaultsAndCancelnotifyWithBlestate:weakself.blestate];
    }];
    
    //发现设备的services委托
    [baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        //zwjLog(@"发现服务");
        //更新蓝牙状态,进入已连接状态
        weakself.blestate=BleStateConnected;
        //weakself.title=weakself.currentdevice.name;
        
    }];
    [baby setBlockOnDidReadRSSI:^(NSNumber *RSSI, NSError *error) {
        //zwjLog(@"当前连接设备的RSSI值为:%@",RSSI);
    }];
    //设置发现services的characteristics
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        zwjLog(@"===service name:%@",service.UUID);
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID.UUIDString isEqualToString:UUIDSTR_ESPRESSIF_Notify])
            {
                //订阅通知
                [weakbaby notify:peripheral characteristic:characteristic block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error){
                     NSData *data=characteristic.value;
                    if (data.length<3) {
                        return ;
                    }
                    zwjLog(@"接收到数据为%@>>>>>>>>>>>>",data);
                    //zwjLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
                    NSMutableData *Mutabledata=[NSMutableData dataWithData:data];
                    [weakself analyseData:Mutabledata];
                    
                     if(weakself.ConnectTimeoutTimer)
                     {
                         //销毁连接超时定时器
                         [weakself.ConnectTimeoutTimer invalidate];
                     }
                         
                    }];
            }
            if ([characteristic.UUID.UUIDString isEqualToString:UUIDSTR_ESPRESSIF_Write])
            {
                zwjLog(@"UUIDSTR_ESPRESSIF_RX");
                _WriteCharacteristic=characteristic;
                
                
                
                
            }
        }
    }];
    
    //读取characteristic
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error)
     {
         
     }];
    
    //设置发现characteristics的descriptors的委托
    [baby setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
    }];
    
    //设置读取Descriptor的委托
    [baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        //Log(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    //断开连接回调
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        if (error) {
            zwjLog(@"断开连接Error %@",error);
        }
        if (weakself.APPCancelConnect) {
            //清标志位
            weakself.APPCancelConnect=NO;
            weakself.blestate=BleStateDisconnect;
             zwjLog(@"设备：%@--断开连接",peripheral.name);
        }
        else{
            //更新蓝牙状态,已连接状态
            weakself.blestate=BleStateReConnect;
            //添加自动回连
            [weakself AutoReconnect:weakself.currentdevice.Peripheral];
             zwjLog(@"设备：%@--重新连接",peripheral.name);
        }
        //断开连接时,如果有数据就保存到数据库
    }];
    //取消所有连接回调
    [baby setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        zwjLog(@"setBlockOnCancelAllPeripheralsConnectionBlock");
    }];
    //********取消扫描回调***********//
    [baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        //Log(@"取消扫描");
        //停止进度条
        [weakself StopProgressView];
         weakself.blestate=BleStateWaitToConnect;
        NSInteger count=weakself.BLEDeviceArray.count;
        if(weakself.popview)
        {
            if (count<=0) {
                weakself.popview.titlelabel.text=NSLocalizedString(@"popviewnodevice", nil);
                //更新蓝牙状态,进入无设备状态
                weakself.blestate=BleStateNoDevice;
            }else
            {
                weakself.popview.titlelabel.text=NSLocalizedString(@"connect", nil);
            }
            return ;
            
        }else
        {
            if (count<=0) {
                weakself.popview.titlelabel.text=NSLocalizedString(@"popviewnodevice", nil);
                //更新蓝牙状态,进入无设备状态
                weakself.blestate=BleStateNoDevice;
            }else if (count>=1) {
                [weakself PopScanViewWithTitle:NSLocalizedString(@"connect", nil)];
            }
        }
        
    }];
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES};
    //连接设备->
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
    //订阅状态改变
    [baby setBlockOnDidUpdateNotificationStateForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        if (error) {
            zwjLog(@"订阅 Error");
        }
        if (characteristic.isNotifying) {
            zwjLog(@"订阅成功");
            //[weakself writeStructDataWithCharacteristic:weakself.WriteCharacteristic WithData:[PacketCommand GetDeviceInforWithSequence:weakself.sequence]];
            [weakself SendNegotiateData];
        }
        else
        {
            zwjLog(@"已经取消订阅");
        }
        
    }];
    //发送数据完成回调
    [weakbaby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error)
     {
         if (error)
         {
             zwjLog(@"%@",error);
             [HUDTips ShowLabelTipsToView:self.navigationController.view WithText:@"command error"];
             return ;
         }
         zwjLog(@"发送数据完成");
        
    }];
}
/**
 *  直连
 *
 *  @param peripheral 要连接的蓝牙设备
 */
-(void)connect:(CBPeripheral *)peripheral
{
    baby.having(peripheral).connectToPeripherals().discoverServices().discoverCharacteristics().begin();
}
//断开自动重连
-(void)AutoReconnect:(CBPeripheral *)peripheral
{
    [baby AutoReconnect:peripheral];
}
//删除自动重连
- (void)AutoReconnectCancel:(CBPeripheral *)peripheral;
{
    [baby AutoReconnectCancel:peripheral];
}

/**
 *  断开连接
 */
-(void)Disconnect:(CBPeripheral *)Peripheral
{
    self.APPCancelConnect=YES;
    //取消某个连接
    [baby cancelPeripheralConnection:Peripheral];
    self.blestate=BleStateDisconnect;
}
//取消所有连接
-(void)CancelAllConnect
{
    if([baby findConnectedPeripherals].count>0)
    {
        self.APPCancelConnect=YES;
        //断开所有蓝牙连接
        [baby cancelAllPeripheralsConnection];
    }
}

/**
 *  蓝牙发送数据
 *
 *  @param Characteristic 特征值
 */
-(void)writeStructDataWithCharacteristic:(CBCharacteristic *)Characteristic WithData:(NSData *)data
{
    if (self.blestate!=BleStateConnected) {
        [HUDTips ShowLabelTipsToView:self.navigationController.view WithText:NSLocalizedString(@"can'tperformtheoperation", nil)];
        return;
    }
    
    if (self.currentdevice.Peripheral && Characteristic)
    {
        zwjLog(@"发送的数据=%@,%ld",data,data.length);
        [[baby findConnectedPeripherals].firstObject writeValue:data forCharacteristic:Characteristic type:CBCharacteristicWriteWithResponse];
        self.sequence=self.sequence+1;
    }
}

//销毁定时器
-(void)invalidateTimer:(NSTimer *)timer
{
    //销毁连接超时定时器
    zwjLog(@"销毁定时器");
    [timer invalidate];
    timer=nil;
}

//通知,重连超时
-(void)ReconnectTimeout
{
    zwjLog(@"ReconnectTimeout");
    //播放提示音
    [LocalNotifyFunc playSound];
    [LocalNotifyFunc CancelLocalWarningWithUserinfor:@"ReconnectTimeout"];
    //重连超时,用户没有干预的话,周期性提醒
    NSString *localStr=[NSString stringWithFormat:@"%@ %@,%@",self.currentdevice.name,NSLocalizedString(@"disconnected", nil),[NSDate allString]];
    [LocalNotifyFunc PostWarningAndLocalNotifyWithUserinfor:@"ReconnectTimeout" WithLocalNotifyString:localStr SinceNow:60 sound:YES repeat:YES];
    //弹出提示框
    [self AlertactionViewWithTitle:NSLocalizedString(@"tips", nil) Message:[NSString stringWithFormat:@"%@,%@",self.currentdevice.name,NSLocalizedString(@"Reconnectthedevice?", nil)] OkactionTitle:NSLocalizedString(@"yes", nil) CancelActionTitle:NSLocalizedString(@"no", nil) AlertActionState:ReconnecttimeoutAction preferredStyle:UIAlertControllerStyleAlert];
}
//连接超时
-(void)ConnectTimeOut
{
    zwjLog(@"ConnectTimeOut");
    //销毁连接超时定时器
    [self invalidateTimer:self.ConnectTimeoutTimer];
    //取消连接,之后会调用连接失败block(iphone6 ios9.3)
    [self Disconnect:self.currentdevice.Peripheral];
    //更新蓝牙状态
    self.blestate=BleStateConnecttimeout;
}

-(void)AlertactionViewWithTitle:(NSString *)title Message:(NSString *)message OkactionTitle:(NSString *)oktitle CancelActionTitle:(NSString *)canceltitle AlertActionState:(AlertActionState)state preferredStyle:(UIAlertControllerStyle)preferredStyle
{
    __weak typeof(self) weakself = self;
    UIAlertController *AlertC=[UIAlertController alertControllerWithTitle:title message:message preferredStyle:preferredStyle];
    UIAlertAction *OKAction=[UIAlertAction actionWithTitle:oktitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        switch (state) {
            case ReconnecttimeoutAction:
            {
                [LocalNotifyFunc CancelLocalWarningWithUserinfor:@"ReconnectTimeout"];
                [self connect:self.currentdevice.Peripheral];

            }
                break;
            case DeviceoverAction:
                weakself.blestate=BleStateIdle;
                break;
            case ConnectingAction:
                if (weakself.blestate==BleStateConnecting || weakself.blestate==BleStateConnected) {
                    //取消连接,之后会调用连接失败block(有bug)
                    [weakself Disconnect:weakself.currentdevice.Peripheral];
                    //更新蓝牙状态
                    weakself.blestate=BleStateIdle;
                    //关闭连接超时定时器
                    [weakself invalidateTimer:weakself.ConnectTimeoutTimer];
                }
                break;
            case DisconnectAction:
                if (weakself.blestate==BleStateConnected) {
                    [weakself Disconnect:weakself.currentdevice.Peripheral];
                }
                break;
            case CancelreconnectAction:
                if (weakself.blestate==BleStateReConnect || weakself.blestate==BleStateConnected) {
                    //取消重连
                    [weakself AutoReconnectCancel:weakself.currentdevice.Peripheral];
                    //取消连接,之后调用连接失败block(必须添加该函数,否则不能真正关闭回连)
                    [weakself Disconnect:weakself.currentdevice.Peripheral];
                    //更新蓝牙状态
                    weakself.blestate=BleStateIdle;
                }
                break;
                
                case StartSensorAction:
            {
                
            
            }
                break;
            
            
                break;
            case ClearData:
                 
                break;
            case DisconnectBLE:
                 [self Disconnect:self.currentdevice.Peripheral];
                break;
                break;
            default:
                break;
        }
        
    }];
    
    UIAlertAction *CancelAction=[UIAlertAction actionWithTitle:canceltitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        switch (state) {
            case ReconnecttimeoutAction:
                [weakself AutoReconnectCancel:weakself.currentdevice.Peripheral];
                [weakself Disconnect:weakself.currentdevice.Peripheral];
                weakself.blestate=BleStateReconnecttimeout;
                [LocalNotifyFunc CancelLocalWarningWithUserinfor:@"ReconnectTimeout"];
                //删除所有周期通知
                //[LocalNotifyFunc DeleteAllUserDefaultsAndCancelnotifyWithBlestate:self.blestate];
                break;
            case DeviceoverAction:
                baby.scanForPeripherals().begin().stop(SCANTIME);
                weakself.blestate=BleStateScan;
                break;
            case ConnectingAction:
                
                break;
            case DisconnectAction:
                
                break;
            case CancelreconnectAction:
                
                break;
                
            default:
                break;
        }
        
    }];
    
    [AlertC addAction:OKAction];
    [AlertC addAction:CancelAction];
    [weakself presentViewController:AlertC animated:YES completion:^{
        
    }];
}
//弹出提示框  蓝牙未连接不能执行该操作提示框
-(void)popviewWithTitle:(NSString *)title message:(NSString *)message
{
    __weak typeof(self) weakself = self;
    UIAlertController *AlertC=[UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *OKAction=[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       
    }];
    [AlertC addAction:OKAction];
    [weakself presentViewController:AlertC animated:YES completion:^{
    }];
}
//蓝牙状态更新调用
-(void)setBlestate:(BleState)blestate
{
    _blestate=blestate;
    switch (blestate) {
        case BleStatePowerOn:
           
            [self StopProgressView];
            [self SetProgressViewTitle:NSLocalizedString(@"poweron", nil) ];
            self.blestate=BleStateIdle;
            break;
        case BleStatePoweroff:
            //[self NotifyMenuVCpresonUsing:NO];
            [self StopProgressView];
            [self SetProgressViewTitle:NSLocalizedString(@"poweroff", nil) ];
            break;
        case BleStateIdle:
            //Log(@"BleStateIdle");
           
            [self StopProgressView];
            //设置环形进度条静态显示
            [self SetProgressViewTitle:NSLocalizedString(@"taptostart", nil) ];
            
            break;
        case BleStateScan:
            //Log(@"BleStateScan");
            
            //启动环形进度条
            [self StartProgressViewWithTitle:NSLocalizedString(@"scaning", nil) ];
            break;
        case BleStateCancelConnect:
            //Log(@"BleStateCancelConnect");
            
            [self SetProgressViewTitle:NSLocalizedString(@"rescan",nil)];
            break;
        case BleStateNoDevice:
            //Log(@"BleStateNoDevice");
            
            [self SetProgressViewTitle:NSLocalizedString(@"nodevice",nil) ];
            break;
        case BleStateWaitToConnect:
            
            [self StopProgressView];
            [self SetProgressViewTitle:NSLocalizedString(@"waittoconnect", nil)];
            break;
        case BleStateConnecting:
            //Log(@"BleStateConnecting");
            
            //启动环形进度条
            [self StartProgressViewWithTitle:NSLocalizedString(@"connecting",nil)];
            //开启连接超时定时器
            [self.ConnectTimeoutTimer invalidate];
            self.ConnectTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:ConnectTime target:self selector:@selector(ConnectTimeOut) userInfo:nil repeats:NO];
            break;
        case BleStateConnected:
            //Log(@"BleStateConnected");
            self.titlelabel.text=self.currentdevice.name;
            //取消重连超时周期警告通知
            [LocalNotifyFunc CancelLocalWarningWithUserinfor:@"ReconnectTimeout"];
            
            //停止环形进度条
            [self StopProgressView];
            //环形进度条切换成渐变色
            [self changeProgressViewWithColor:YES];
            //设置环形进度条静态显示
            [self SetProgressViewTitle:NSLocalizedString(@"connected",nil) ]; //蓝牙已连接显示,重连进度屏蔽以后,此提示也屏蔽
            
            self.ConfigBtn.hidden=NO;
           
            //保存连接后的设备
            [[NSUserDefaults standardUserDefaults] setObject:self.currentdevice.Peripheral.identifier.UUIDString forKey:ConnectedDeviceKey];
            [[NSUserDefaults standardUserDefaults] setObject:self.currentdevice.name forKey:ConnectedDeviceNameKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            break;
        case BleStateDisconnect:
            //Log(@"BleStateDisconnect");
            //停止环形进度条
            [self StopProgressView];
            //环形进度条切换成单色
            [self changeProgressViewWithColor:NO];
            //设置环形进度条静态显示
            [self SetProgressViewTitle:NSLocalizedString(@"disconnect", nil)];

            
            self.titlelabel.text=@"No Device";
            self.sequence=0;
            self.ConfigBtn.hidden=YES;
            
            
            //删除保存的连接信息
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:ConnectedDeviceKey];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:ConnectedDeviceNameKey];
            
            self.rsaobject=nil;
            self.senddata=nil;
            self.Securtkey=nil;
            
            
            break;
        case BleStateReConnect:
        {
            //NSString *localStr=[NSString stringWithFormat:@"%@ %@,%@",self.currentdevice.name,NSLocalizedString(@"disconnected", nil),[NSDate allString]];
            //[LocalNotifyFunc PostWarningAndLocalNotifyWithUserinfor:@"ReconnectTimeout" WithLocalNotifyString:localStr SinceNow:ReconnectTime sound:NO repeat:YES];
            //环形进度条切换成单色
            //[self changeProgressViewWithColor:NO];
            //启动环形进度条,重新连接设备
            //[self StartProgressViewWithTitle:NSLocalizedString(@"reconnecting", nil)];
            //[self SetProgressbottomTitle:@""];
            self.sequence=0;
            
            self.rsaobject=nil;
            self.senddata=nil;
            self.Securtkey=nil;
        }
            break;
        case BleStateUnknown:
            
            [self SetProgressViewTitle:NSLocalizedString(@"noble", nil) ];
            break;
        case BleStateConnecttimeout:
            
            [self StopProgressView];
            [self SetProgressViewTitle:NSLocalizedString(@"connecttimeout", nil)];
            break;
        case BleStateReconnecttimeout:
            
            [self StopProgressView];
            [self SetProgressViewTitle:NSLocalizedString(@"reconnecttimeout", nil)];
            break;
        
        default:
            break;
    }
}



-(void)setActivemode:(ActiveMode)activemode
{
    _activemode=activemode;
    
    switch (activemode) {
        case ForegroundMode:
            break;
        case backgroundMode:
             zwjLog(@"backgroundMode");
            break;
        default:
            break;
    }
}

//弹出扫描提示view
-(PopView *)PopScanViewWithTitle:(NSString *)title
{
    UIView *backView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    backView.backgroundColor=[[UIColor blackColor] colorWithAlphaComponent:0.3];
    PopView *popview=[PopView instancePopView];
    popview.titlelabel.text=title;
    popview.center=self.view.center;
    popview.bounds=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width-20, 300);
    popview.dataArray=self.BLEDeviceArray;
    popview.popdelegate=self;
    [backView addSubview:popview];
    [[UIApplication sharedApplication].keyWindow addSubview:backView];
    
    return popview;
}
//popview delegate,隐藏移除popview
-(void)HidePopView
{
    self.popview=nil;
    if (self.blestate==BleStateWaitToConnect) {
        self.blestate=BleStateCancelConnect;
    }
}
//popview delegate
-(void)PopViewSelectIndex:(NSInteger)index
{
    if (self.blestate==BleStateScan){
        [baby babyStop];
    }
    if (index>=self.BLEDeviceArray.count) {
        return;
    }
    //取出设备
    BLEDevice *device=self.BLEDeviceArray[index];
    CBPeripheral *Peripheral=device.Peripheral;
    //连接
    [self connect:Peripheral];
    //更新蓝牙状态,进入连接状态
    self.blestate=BleStateConnecting;
    //保存当前要连接的设备信息
    self.currentdevice=device;
    [self.popview.superview removeFromSuperview];
    [self.popview removeFromSuperview];
    self.popview=nil;
}

-(void)dealloc
{
    zwjLog(@"%s",__func__);
}

//menuDelegate 代理
-(void)didClickMenuIndex:(NSInteger)index
{
    zwjLog(@"index=%ld",index);
}

-(void)analyseData:(NSMutableData *)data
{
    Byte *dataByte = (Byte *)[data bytes];
    
    Byte Type=dataByte[0] & 0x03;
    Byte sequence=dataByte[2];
    Byte frameControl=dataByte[1];
    Byte length=dataByte[3];

    BOOL hash=frameControl & Packet_Hash_FrameCtrlType;
    BOOL checksum=frameControl & Data_End_Checksum_FrameCtrlType;
    //BOOL Drection=frameControl & Data_Direction_FrameCtrlType;
    BOOL Ack=frameControl & ACK_FrameCtrlType;
    BOOL AppendPacket=frameControl & Append_Data_FrameCtrlType;
    
    if (hash) {
        zwjLog(@"加密");
        //解密
        NSRange range=NSMakeRange(4, length);
        NSData *Decryptdata=[data subdataWithRange:range];
        Byte *byte=(Byte *)[Decryptdata bytes];
        Decryptdata=[DH_AES blufi_aes_DecryptWithSequence:sequence data:byte len:length KeyData:self.Securtkey];
        [data replaceBytesInRange:range withBytes:[Decryptdata bytes]];
        
    }else{
        zwjLog(@"无加密");
    }
    if (checksum) {
        zwjLog(@"有校验");
        //计算校验
        if ([PacketCommand VerifyCRCWithData:data]) {
            zwjLog(@"校验成功");
        }else
        {
            zwjLog(@"校验失败,返回");
            [HUDTips ShowLabelTipsToView:self.view WithText:@"校验失败"];
            return;
        }
        
    }
    else{
        zwjLog(@"无校验");
    }
    if(Ack)
    {
        zwjLog(@"回复ACK");
        [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand ReturnAckWithSequence:self.sequence BackSequence:sequence]];
    }else{
        zwjLog(@"不回复ACK");
    }
    if (AppendPacket) {
        zwjLog(@"有后续包");
    }else{
        zwjLog(@"没有后续包");
    }

    if (Type==ContolType)
    {
        //zwjLog(@"接收到控制包===========");
        [self GetControlPacketWithData:data];
    }
    else if (Type==DataType)
    {
        //zwjLog(@"接收到数据包===========");
        [self GetDataPackectWithData:data];
    }
    else
    {
        zwjLog(@"异常数据包");
        [HUDTips ShowLabelTipsToView:self.view WithText:@"异常数据包"];
    }
}
-(void)GetControlPacketWithData:(NSData *)data
{
    
    Byte *dataByte = (Byte *)[data bytes];
    Byte SubType=dataByte[0]>>2;
    switch (SubType) {
        case ACK_Esp32_Phone_ControlSubType:
        {
            zwjLog(@"接收到ACK<<<<<<<<<<<<<<<");
        }
            break;
        case ESP32_Phone_Security_ControlSubType:
            break;
            
        case Wifi_Op_ControlSubType:
            break;
            
        case Connect_AP_ControlSubType:
            break;
        case Disconnect_AP_ControlSubType:
            break;
        case Get_Wifi_Status_ControlSubType:
            break;
        case Deauthenticate_STA_Device_SoftAP_ControlSubType:
            break;
        case Get_Version_ControlSubType:
            break;
        case Negotiate_Data_ControlSubType:
            break;
            
        default:
            break;
    }

}

-(void)GetDataPackectWithData:(NSData *)data
{
    
    Byte *dataByte = (Byte *)[data bytes];
    Byte SubType=dataByte[0]>>2;
    Byte length=dataByte[3];
    
    switch (SubType) {
        case Negotiate_Data_DataSubType: //
        {
            if (data.length<length+4) {
                zwjLog(@"数据异常");
                [HUDTips ShowLabelTipsToView:self.view WithText:@"数据异常"];
                return;
            }
            NSData *NegotiateData=[data subdataWithRange:NSMakeRange(4, length)];
            self.Securtkey=[DH_AES GetSecurtKey:NegotiateData RsaObject:self.rsaobject];
            //设置加密模式
            NSData *SetSecuritydata=[PacketCommand SetESP32ToPhoneSecurityWithSecurity:YES CheckSum:YES Sequence:self.sequence];
            [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:SetSecuritydata];
            
            //获取状态报告
            [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:[PacketCommand GetDeviceInforWithSequence:self.sequence]];
        }
            break;
            
        case BSSID_STA_DataSubType:
            
            break;
        case SSID_STA_DataSubType:
            
            break;
        case Password_STA_DataSubType:
            
            break;
        case SSID_SoftaAP_DataSubType:
            
            break;
        case Password_SoftAP_DataSubType:
            
            break;
        case Max_Connect_Number_SoftAP_DataSubType:
            
            break;
        case Authentication_SoftAP_DataSubType:
            
            break;
        case Channel_SoftAP_DataSubType:
            
            break;
            
        case Username_DataSubType:
            
            break;
        case CA_Certification_DataSubType:
            
            break;
        case Client_Certification_DataSubType:
            
            break;
        case Server_Certification_DataSubType:
            
            break;
        case Client_PrivateKey_DataSubType:
            
            break;
            
        case Server_PrivateKey_DataSubType:
            
            break;
        case Wifi_Connection_state_Report_DataSubType: //连接状态报告
        {
            if (length<3) {
                return;
            }
            zwjLog(@"接收到连接状态包<<<<<<<<<<<<<<<<");
            NSString *OpmodeTitle;
            switch (dataByte[4])
            {
                case NullOpmode:
                {
                    OpmodeTitle=@"Null Mode";
                    
                }
                    break;
                case STAOpmode:
                    OpmodeTitle=@"STA mode";
                    
                    break;
                case SoftAPOpmode:
                    OpmodeTitle=@"SoftAP mode";
                    
                    break;
                case SoftAP_STAOpmode:
                    OpmodeTitle=@"SoftAP/STA mode";
                    
                    break;
                    
                default:
                    OpmodeTitle=@"Unknown mode";

                    break;
            }
            zwjLog(@"%@",OpmodeTitle);
            self.Opmodelabel.text=OpmodeTitle;
            
            NSString *StateTitle;
            if (dataByte[5]==0x0) {
                StateTitle=@"STA连接状态";
            }else
            {
                StateTitle=@"STA非连接状态";
            }
            zwjLog(@"%@",StateTitle);
            self.STAStatelabel.text=StateTitle;
            
            zwjLog(@"SoftAP连接状态,%d 个STA",dataByte[6]);
            self.STACountlabel.text=[NSString stringWithFormat:@"SoftAP连接设备数量:%d",dataByte[6]];
            self.BSSidSTAlabel.text=@"";
            self.SSidSTAlabel.text=@"";
            if(length==0x13)
            {
                NSString *SSID=[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(17, dataByte[16])] encoding:NSASCIIStringEncoding];
                self.SSidSTAlabel.text=[NSString stringWithFormat:@"STA_WIFI_SSID:%@",SSID];
                self.BSSidSTAlabel.text=[NSString stringWithFormat:@"STA_WIFI_BSSID:%02x%02x%02x%02x%02x%02x",dataByte[9],dataByte[10],dataByte[11],dataByte[12],dataByte[13],dataByte[14]];
            }
        }
            break;
        case Version_DataSubType:
            
            break;
            
        default:
            break;
    }


}

//发送协商数据包
-(void)SendNegotiateData
{
    if (!self.rsaobject) {
        self.rsaobject=[DH_AES DHGenerateKey];
    }
    NSInteger datacount=80;
    //发送数据长度
    uint16_t length=self.rsaobject.P.length+self.rsaobject.g.length+self.rsaobject.PublickKey.length+6;
    [self writeStructDataWithCharacteristic:self.WriteCharacteristic WithData:[PacketCommand SetNegotiatelength:length Sequence:self.sequence]];
    
    //发送数据,需要分包
    self.senddata=[PacketCommand GenerateNegotiateData:self.rsaobject];
    NSInteger number=self.senddata.length/datacount;
    if (number>0) {
        for(NSInteger i=0;i<number+1;i++)
        {
            if (i==number) {
                [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:NO block:^(NSTimer * _Nonnull timer)
                {
                    NSData *data=[PacketCommand SendNegotiateData:self.senddata Sequence:self.sequence Frag:NO TotalLength:self.senddata.length];
                    [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:data];
                }];
                
            }
            else
            {
                [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:NO block:^(NSTimer * _Nonnull timer)
                {
                     NSData *data=[PacketCommand SendNegotiateData:[self.senddata subdataWithRange:NSMakeRange(0, datacount)] Sequence:self.sequence Frag:YES TotalLength:self.senddata.length];
                     [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:data];
                     self.senddata=[self.senddata subdataWithRange:NSMakeRange(datacount, self.senddata.length-datacount)];
                 }];
            }
        }
        
    }else
    {
        NSData *data=[PacketCommand SendNegotiateData:self.senddata Sequence:self.sequence Frag:NO TotalLength:self.senddata.length];
        [self writeStructDataWithCharacteristic:_WriteCharacteristic WithData:data];
    }
}


@end
