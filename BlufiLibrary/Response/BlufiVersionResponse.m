//
//  BlufiVersionResponse.m
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "BlufiVersionResponse.h"

@implementation BlufiVersionResponse

- (NSString *)getVersionString {
    return [NSString stringWithFormat:@"V%d.%d", _bigVer, _smallVer];
}

@end
