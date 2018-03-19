
//
//  SetPassController.m
//  DJRegisterViewDemo
//
//  Created by zhi weijian.
//  Copyright (c) 2016年 zhi weijian. All rights reserved.
//

#import "SetPassController.h"
#import "DJRegisterView.h"
@interface SetPassController ()

@end

@implementation SetPassController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DJRegisterView *djSetPassView = [[DJRegisterView alloc]
                                     initwithFrame:self.view.bounds action:^(NSString *key1, NSString *key2) {
                                         //Log(@"key1=%@,key2=%@",key1,key2);
                                         
                                     }];
    [self.view addSubview:djSetPassView];
    
}
@end
