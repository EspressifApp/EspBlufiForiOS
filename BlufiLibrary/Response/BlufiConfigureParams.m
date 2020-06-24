//
//  BlufiConfigureParams.m
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "BlufiConfigureParams.h"

@implementation BlufiConfigureParams

- (NSString *)description
{
    return [NSString stringWithFormat:@"opMode=%u, staBssid=%@, staSsid=%@, staPassword=%@, softapSecurity=%u, softapSsid=%@, softapPassword=%@, softapChannel=%ld, softapMaxConnection=%ld", _opMode, _staBssid, _staSsid, _staPassword, _softApSecurity, _softApSsid, _softApPassword, (long)_softApChannel, (long)_softApMaxConnection];
}

@end
