//
//  OpmodeObject.h
//  EspBlufi
//
//  Created by zhiweijian on 27/03/2017.
//  Copyright © 2017 zhi weijian. All rights reserved.
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
