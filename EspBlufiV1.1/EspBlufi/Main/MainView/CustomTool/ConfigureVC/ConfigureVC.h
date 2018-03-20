//
//  ConfigureVC.h
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <UIKit/UIKit.h>
#import "PacketCommand.h"

@class OpmodeObject;

@protocol ConfigVCDelegate <NSObject>

-(void)SetOpmode:(Opmode)mode Object:(OpmodeObject *)object openmode:(BOOL)open;

@end

@interface ConfigureVC : UIViewController


@property(nonatomic,weak)id<ConfigVCDelegate>delegate;

@end
