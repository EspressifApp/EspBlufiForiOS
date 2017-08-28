//
//  BLEViewController.h
//  
//
//  Created by zhi weijian on 16/6/7.
//  Copyright © 2016年 zhi weijian. All rights reserved.
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
