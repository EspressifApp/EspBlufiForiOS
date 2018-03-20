//
//  OpmodeObject.h
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <Foundation/Foundation.h>

@interface OpmodeObject : NSObject

@property(nonatomic,copy)NSString *WifiSSid;
@property(nonatomic,copy)NSString *WifiPassword;

@property(nonatomic,copy)NSString *SoftAPSSid;
@property(nonatomic,copy)NSString *SoftAPPassword;

@property(nonatomic,assign)uint8_t channel;
@property(nonatomic,assign)uint8_t max_Connect;
@property(nonatomic,assign)uint8_t Security;



@end
