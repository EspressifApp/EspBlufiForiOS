//
//  BlufiFrameCtrlData.h
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlufiConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlufiFrameCtrlData : NSObject

- (instancetype)initWithValue:(Byte)value;

- (BOOL)isEncrypted;

- (BOOL)isChecksum;

- (BOOL)isAckRequirement;

- (BOOL)hasFrag;

+ (Byte)getFrameCtrlValueWithEncrypted:(BOOL)encrypted checksum:(BOOL)checksum direction:(DataDirection)direction requireAck:(BOOL)ack hasFrag:(BOOL)frag;

@end

NS_ASSUME_NONNULL_END
