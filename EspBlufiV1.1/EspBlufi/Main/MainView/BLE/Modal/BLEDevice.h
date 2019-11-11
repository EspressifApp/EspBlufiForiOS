//
//  BLEDevice.h
//  
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
//蓝牙设备模型,包括蓝牙名称和蓝牙信息
@interface BLEDevice : NSObject

@property(nonatomic,copy)NSString *name;
@property(nonatomic,strong)CBPeripheral *Peripheral;
@property(nonatomic,assign) BOOL isConnected;
@property(nonatomic, strong) NSString *uuidBle;
@end
