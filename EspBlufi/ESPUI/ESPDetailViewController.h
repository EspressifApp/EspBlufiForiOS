//
//  ESPDetailViewController.h
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/10.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESPPeripheral.h"

NS_ASSUME_NONNULL_BEGIN

@interface ESPDetailViewController : UIViewController

@property(strong, nonatomic)ESPPeripheral *device;

@end

NS_ASSUME_NONNULL_END
