//
//  NoneUser.m
//  FiberSense
//
//  Created by zhi weijian on 16/6/14.
//  Copyright © 2016年 zhi weijian. All rights reserved.
//

#import "NoneUser.h"
#import "ProfrieTableViewController.h"

#define ScreenW [UIScreen mainScreen].bounds.size.width

@implementation NoneUser


- (void)drawRect:(CGRect)rect {
    // Drawing code
    //self.backgroundColor=[UIColor colorWithRed:200/256.0 green:225/256.0 blue:225/256.0 alpha:1];
    //self.backgroundColor=[UIColor redColor];
    UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height/4, ScreenW, 30)];
    //label.text=@"您还没有添加成员哦~";
    label.text=NSLocalizedString(@"Noneusertips", nil);
    label.textColor=[UIColor lightGrayColor];
    label.textAlignment=NSTextAlignmentCenter;
    [self addSubview:label];
    UIButton *button=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    //button.layer.cornerRadius=5;
    //button.backgroundColor=[UIColor blueColor];
    UIImage *image=[UIImage imageNamed:@"tempadd"];
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    button.bounds=CGRectMake(0, 0, 60, 60);
    button.center=CGPointMake(self.center.x, self.center.y);
    [button setTitle:NSLocalizedString(@"adduser", nil) forState:UIControlStateNormal];
    [button addTarget:self action:@selector(addNewUser) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
}
-(void)addNewUser
{
    if ([self.delegate respondsToSelector:@selector(EnterAddUserView)]) {
        [self.delegate EnterAddUserView];
    }
    
}

-(void)dealloc
{
    //Log(@"%s",__func__);
}

@end
