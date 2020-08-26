//
//  ESPPeripheral.m
//  EspBlufi
//
//  Created by AE on 2020/6/15.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "ESPPeripheral.h"

@implementation ESPPeripheral

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral {
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _uuid = peripheral.identifier;
    }
    return self;
}

@end
