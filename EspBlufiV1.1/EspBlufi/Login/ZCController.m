
//
//  ZCController.m
//  DJRegisterViewDemo
//
//  Created by zhi weijian.
//  Copyright (c) 2016年 zhi weijian. All rights reserved.
//

#import "ZCController.h"
#import "DJRegisterView.h"
#import "SetPassController.h"
@interface ZCController ()

@end

@implementation ZCController

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.title=@"注册";
    self.title=NSLocalizedString(@"registertitle", nil);
    DJRegisterView *djzcView = [[DJRegisterView alloc]
                                initwithFrame:self.view.bounds djRegisterViewTypeSMS:DJRegisterViewTypeScanfPhoneSMS plTitle:NSLocalizedString(@"enter_code", nil) //@"请输入获取到的验证码"
                                title:NSLocalizedString(@"next", nil)
                                
                                hq:^BOOL(NSString *phoneStr) {
                                    //手机号码
                                    //Log(@"phoneStr=%@",phoneStr);
                                    if(phoneStr.length!=11)
                                    {
                                        //[self ShowAlertViewWithTitle:@"警告" WithMessage:@"请输入正确的手机号码!"];
                                        [self ShowAlertViewWithTitle:NSLocalizedString(@"warning", nil) WithMessage:NSLocalizedString(@"entercorrectphone", nil)];
                                        return NO;
                                    }
                                    
                                    return YES;
                                }
                                
                                tjAction:^(NSString *yzmStr) {
                                    //验证码
                                    //Log(@"yzmStr=%@",yzmStr);
                                    //测试用
                                    SetPassController *setpassVc=[[SetPassController alloc]init];
                                    setpassVc.view.backgroundColor=[UIColor whiteColor];
                                    [self.navigationController pushViewController:setpassVc animated:YES];
                                    
                                    
                                }];
    [self.view addSubview:djzcView];
}
-(void)ShowAlertViewWithTitle:(NSString *)title WithMessage:(NSString *)message
{
    UIAlertController *AlertVc=[UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *OKaction=[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [AlertVc addAction:OKaction];
    [self presentViewController:AlertVc animated:YES completion:^{
        
    }];
}

@end
