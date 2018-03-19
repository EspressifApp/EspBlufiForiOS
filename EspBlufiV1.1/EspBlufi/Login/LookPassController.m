//
//  LookPassController.m
//  DJRegisterViewDemo
//
//  Created by zhi weijian.
//  Copyright (c) 2016年 zhi weijian. All rights reserved.
//

#import "LookPassController.h"
#import "DJRegisterView.h"
@interface LookPassController ()

@end

@implementation LookPassController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    DJRegisterView *djzcView = [[DJRegisterView alloc]
                                initwithFrame:self.view.bounds djRegisterViewTypeSMS:DJRegisterViewTypeNoScanfSMS plTitle:@"请输入验证码"
                                title:@"提交"
                                
                                hq:^BOOL(NSString *phoneStr) {
                                    
                                    return YES;
                                }
                                
                                tjAction:^(NSString *yzmStr) {
                                    
                                }];
    [self.view addSubview:djzcView];
}
@end
