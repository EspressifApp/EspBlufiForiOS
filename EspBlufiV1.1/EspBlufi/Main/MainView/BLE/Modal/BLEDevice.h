//
//  BLEDevice.h
//  
//
//  Created by zhi weijian on 16/6/1.
//  Copyright © 2016年 zhi weijian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
//蓝牙设备模型,包括蓝牙名称和蓝牙信息
@interface BLEDevice : NSObject

@property(nonatomic,copy)NSString *name;
@property(nonatomic,strong)CBPeripheral *Peripheral;
@end
