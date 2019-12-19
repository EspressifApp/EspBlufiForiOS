//
//  sendViewController.m
//  EspBlufi
//
//  Created by fanbaoying on 2019/1/21.
//  Copyright © 2019年 zhi weijian. All rights reserved.
//

#import "sendViewController.h"
#import "UIColor+Hex.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
@interface sendViewController ()

@property(strong, nonatomic)UITextField *sendDataTextField;

@end

@implementation sendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    UIImage *backimage=[UIImage imageNamed:@"back_normal"];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[backimage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:(UIBarButtonItemStylePlain) target:self action:@selector(didClickLeftBarBtnIem:)];
    self.navigationItem.title = @"发送数据";
    
    [self sendView];
}

- (void)sendView {
    self.sendDataTextField = [[UITextField alloc]initWithFrame:CGRectMake(10, 20, SCREEN_WIDTH-20, 50)];
//    self.sendDataTextField.backgroundColor = [UIColor colorWithHexString:@"#e6e6e6"];
    self.sendDataTextField.placeholder = @"请输入需要发送的数据";
    [self.view addSubview:_sendDataTextField];
    
    UIView *WifiSsidline=[[UIView alloc]initWithFrame:CGRectMake(10, 70, SCREEN_WIDTH - 20, 1)];
    WifiSsidline.backgroundColor=[UIColor lightGrayColor];
    [self.view addSubview:WifiSsidline];
    
    UIButton *sendBtn = [[UIButton alloc]initWithFrame:CGRectMake(120, 90, SCREEN_WIDTH-240, 50)];
    //btn.backgroundColor=[UIColor redColor];
    [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    [sendBtn setBackgroundColor:[UIColor colorWithHexString:@"#7aC4Eb"]];
    sendBtn.layer.cornerRadius=sendBtn.bounds.size.height/2;
    sendBtn.layer.masksToBounds=YES;
    [sendBtn addTarget:self action:@selector(sendBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendBtn];
}

- (void)sendBtnClick:(UIButton *)sender {
    //     send custom data
    if ([self.sendDataTextField.text isEqualToString:[NSString stringWithFormat:@""]]) {
        NSLog(@"请输入自定义数据");
    }else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sendDtaNotification" object:@{@"customData":self.sendDataTextField.text}];
    }
}

- (void)didClickLeftBarBtnIem:(UIBarButtonItem *)sender
{
    //Log(@"didClickLeftBarBtnIem");
    [self.navigationController popViewControllerAnimated:YES];
    
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
