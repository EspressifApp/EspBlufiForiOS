//
//  HUDTips.h
//  EspBlufi
//
//  Created by zhi weijian on 16/9/27.
//  Copyright © 2016年 zhi weijian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"
@interface HUDTips : NSObject
+ (void)ShowLabelTipsToView:(UIView *)view WithText:(NSString *)text;
+(void)popcustomTipswithImagename:(NSString *)name WithTitle:(NSString *)title;
+(MBProgressHUD *)PopRefeshViewWithTitle:(NSString *)title;
+(MBProgressHUD *)RefreshViewWithLabel:(NSString *)str ToView:(UIView *)view;
@end
