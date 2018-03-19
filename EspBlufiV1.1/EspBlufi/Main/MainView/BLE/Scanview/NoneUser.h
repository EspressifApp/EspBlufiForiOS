//
//  NoneUser.h
//  FiberSense
//
//  Created by zhi weijian on 16/6/14.
//  Copyright © 2016年 zhi weijian. All rights reserved.
//

#import <UIKit/UIKit.h>
//登录后没有用户信息,显示该界面
@protocol NoneUserDelegate <NSObject>
@optional
-(void)EnterAddUserView;

@end

@interface NoneUser : UIView

@property(nonatomic,weak)id<NoneUserDelegate>delegate;

@end
