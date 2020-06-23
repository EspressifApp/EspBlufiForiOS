//
//  HUDTips.m
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/11.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "HUDTips.h"

@implementation HUDTips

+(void)popcustomTipswithImagename:(NSString *)name WithTitle:(NSString *)title
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.contentColor=[UIColor whiteColor];
    hud.bezelView.color=[UIColor blackColor];
    hud.bezelView.alpha=0.8;
    // Set the custom view mode to show any view.
    hud.mode = MBProgressHUDModeCustomView;
    // Set an image view with a checkmark.
    UIImage *image = [[UIImage imageNamed:name] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    hud.customView = [[UIImageView alloc] initWithImage:image];
    // Looks a bit nicer if we make it square.
    hud.square = YES;
    // Optional label text.
    hud.label.text = title;
    
    [hud hideAnimated:YES afterDelay:3.f];
}
+ (void)ShowLabelTipsToView:(UIView *)view WithText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.contentColor=[UIColor whiteColor];
    hud.bezelView.color=[UIColor blackColor];
    hud.bezelView.alpha=0.8;
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    // Move to bottm center.
    //hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    
    [hud hideAnimated:YES afterDelay:1.f];
}

+(MBProgressHUD *)PopRefeshViewWithTitle:(NSString *)title
{

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.contentColor=[UIColor whiteColor];
    hud.bezelView.color=[UIColor blackColor];
    hud.bezelView.alpha=0.8;
    // Set the custom view mode to show any view.
    //hud.mode = MBProgressHUDModeCustomView;
    // Set an image view with a checkmark.
//    UIImage *image = [[UIImage imageNamed:name] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    hud.customView = [[UIImageView alloc] initWithImage:image];
    // Looks a bit nicer if we make it square.
    hud.square = NO;
    // Optional label text.
    hud.label.text = title;
    
    //[hud hideAnimated:YES afterDelay:1.f];
    return hud;
}

+(MBProgressHUD *)RefreshViewWithLabel:(NSString *)str ToView:(UIView *)view
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.contentColor=[UIColor whiteColor];
    hud.bezelView.color=[UIColor blackColor];
    hud.bezelView.alpha=0.8;
    hud.label.text = str;
    
    return hud;
}


@end
