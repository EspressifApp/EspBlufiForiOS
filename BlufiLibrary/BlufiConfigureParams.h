//
//  BlufiConfigureParams.h
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlufiConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlufiConfigureParams : NSObject

@property(assign, nonatomic)OpMode opMode;

@property(strong, nonatomic)NSString *staBssid;
@property(strong, nonatomic)NSString *staSsid;
@property(strong, nonatomic)NSString *staPassword;

@property(assign, nonatomic)SoftAPSecurity softApSecurity;
@property(strong, nonatomic)NSString *softApSsid;
@property(strong, nonatomic)NSString *softApPassword;
@property(assign, nonatomic)NSInteger softApChannel;
@property(assign, nonatomic)NSInteger softApMaxConnection;

@end

NS_ASSUME_NONNULL_END
