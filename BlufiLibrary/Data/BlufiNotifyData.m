//
//  BlufiNotifyData.m
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "BlufiNotifyData.h"

@interface BlufiNotifyData()

@property(strong, nonatomic)NSMutableData *data;

@end

@implementation BlufiNotifyData

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)appendData:(NSData *)data {
    [_data appendData:data];
}

- (NSData *)getData {
    return [NSData dataWithData:_data];
}

@end
