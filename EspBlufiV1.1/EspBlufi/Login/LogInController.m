//
//  LogInController.m
//  DJRegisterViewDemo
//
//  Created by zhi weijian.
//  Copyright (c) 2016年 zhi weijian. All rights reserved.
//

#import "LogInController.h"
#import "DJRegisterView.h"
#import "ZCController.h"
#import "MenuViewController.h"
#import "BLEViewController.h"
@interface LogInController ()

@end

@implementation LogInController

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.title=@"登录";
    self.title=NSLocalizedString(@"LoginTitle", nil);
    DJRegisterView *registerView = [[DJRegisterView alloc]initwithFrame:self.view.bounds
                                    djRegisterViewType:DJRegisterViewTypeNav action:^(NSString *acc, NSString *key) {
                                        //Log(@"点击了登录");
                                        //Log(@"\n输入的账户%@\n密码%@",acc,key);
                                        //测试用
                                        [self EnterInNextView];
                                    } zcAction:^{
                                        //Log(@"点击了 注册");
                                        ZCController *ZCVC=[[ZCController alloc]init];
                                        ZCVC.view.backgroundColor=[UIColor whiteColor];
                                        [self.navigationController pushViewController:ZCVC animated:YES];
                                    } wjAction:^{
                                        //Log(@"点击了   忘记密码");
                                    }];
    [self.view addSubview:registerView];
}
-(void)EnterInNextView
{
    
    BLEViewController *BleVC=[[BLEViewController alloc]init];
    UINavigationController *Nav=[[UINavigationController alloc]initWithRootViewController:BleVC];
    //抽屉栏
    MenuViewController *MenuVC=[MenuViewController instanceWithLeftViewController:nil centerViewController:Nav];
    //读取本地信息
    NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    NSString *path=[docPath stringByAppendingPathComponent:@"Person.plist"];
    NSMutableArray *Array=[NSKeyedUnarchiver unarchiveObjectWithFile:path];
    if (!Array) {
        Array=[NSMutableArray array];
    }
    //设置传递参数
    [MenuViewController getMenuViewController].menuArray =Array;
    [MenuViewController getMenuViewController].PhoneNumber=@"1234567890";
    Array=nil;
    //[self.navigationController pushViewController:MenuVC animated:YES];
    [self presentViewController:MenuVC animated:YES completion:^{
        
    }];
    
}

@end
