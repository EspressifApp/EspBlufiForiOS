//
//  ESPProvisionViewController.h
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/11.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlufiConfigureParams.h"
#import "BlufiConstants.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ConfigureParamsDelegate <NSObject>

@required

- (void)didSetParams:(BlufiConfigureParams *)params;

@end

@interface ESPProvisionViewController : UIViewController

@property(nonatomic, weak)id<ConfigureParamsDelegate> paramsDelegate;

@end

NS_ASSUME_NONNULL_END
