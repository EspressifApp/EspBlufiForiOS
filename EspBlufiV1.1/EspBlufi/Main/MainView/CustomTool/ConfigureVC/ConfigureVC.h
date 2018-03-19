//
//  ConfigureVC.h
//  EspBlufi
//
//  Created by zhiweijian on 24/03/2017.
//  Copyright © 2017 zhi weijian. All rights reserved.
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
