//
//  BlufiScanResponse.h
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlufiScanResponse : NSObject

@property(assign, nonatomic)int type;
@property(strong, nonatomic)NSString *ssid;
@property(assign, nonatomic)int8_t rssi;

@end

NS_ASSUME_NONNULL_END
