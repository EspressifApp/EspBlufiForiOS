//
//  ESPFBYBLEHelper.h
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/11.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESPPeripheral.h"

NS_ASSUME_NONNULL_BEGIN

@interface ESPFBYBLEHelper : NSObject
typedef void(^FBYBleDeviceBackBlock)(ESPPeripheral *device);

@property (nonatomic, copy) FBYBleDeviceBackBlock bleScanSuccessBlock;
/**
 * 单例构造方法
 * @return ESPFBYLocalAPI共享实例
 */
+ (instancetype)share;

//停止扫描
- (void)stopScan;
//开始扫描
- (void)startScan:(FBYBleDeviceBackBlock)device;

@end

NS_ASSUME_NONNULL_END
