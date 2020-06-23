//
//  HUDTips.h
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/11.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUDTips : NSObject
+ (void)ShowLabelTipsToView:(UIView *)view WithText:(NSString *)text;
+(void)popcustomTipswithImagename:(NSString *)name WithTitle:(NSString *)title;
+(MBProgressHUD *)PopRefeshViewWithTitle:(NSString *)title;
+(MBProgressHUD *)RefreshViewWithLabel:(NSString *)str ToView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
