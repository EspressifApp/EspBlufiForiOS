//
//  BlufiFrameCtrlData.m
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "BlufiFrameCtrlData.h"

@interface BlufiFrameCtrlData()

@property(assign, nonatomic,)Byte value;

@end

@implementation BlufiFrameCtrlData

enum {
    PositionEncrypted = 0,
    PositionChecksum,
    PositionDataDirection,
    PositionRequireAck,
    PositionFrag,
};

- (instancetype)initWithValue:(Byte)value {
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

- (BOOL)check:(uint32_t)position {
    return (_value >> position & 1) == 1;
}

- (BOOL)isEncrypted {
    return [self check:PositionEncrypted];
}

- (BOOL)isChecksum {
    return [self check:PositionChecksum];
}

- (BOOL)isAckRequirement {
    return [self check:PositionRequireAck];
}

- (BOOL)hasFrag {
    return [self check:PositionFrag];
}

+ (Byte)getFrameCtrlValueWithEncrypted:(BOOL)encrypted checksum:(BOOL)checksum direction:(DataDirection)direction requireAck:(BOOL)ack hasFrag:(BOOL)frag {
    Byte frame = 0;
    if (encrypted) {
        frame |= (1 << PositionEncrypted);
    }
    if (checksum) {
        frame |= (1 << PositionChecksum);
    }
    if (direction == DataInput) {
        frame |= (1 << PositionDataDirection);
    }
    if (ack) {
        frame |= (1 << PositionRequireAck);
    }
    if (frag) {
        frame |= (1 << PositionFrag);
    }
    return frame;
}

@end
