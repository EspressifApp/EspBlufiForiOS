//
//  BLEViewController.h
//  
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <UIKit/UIKit.h>

@interface BLEViewController : UIViewController
typedef enum {
    BleStateUnknown=0,
    BleStatePowerOn,
    BleStatePoweroff,
    BleStateIdle,
    BleStateScan,
    BleStateCancelConnect,
    BleStateNoDevice,
    BleStateWaitToConnect,
    BleStateConnecting,
    BleStateConnected,
    BleStateDisconnect,
    BleStateReConnect,
    BleStateConnecttimeout,
    BleStateReconnecttimeout,
    //BleStateShutdown,
}BleState;

@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
