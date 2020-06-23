//
//  BlufiStatusResponse.m
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "BlufiStatusResponse.h"

@implementation BlufiStatusResponse

- (instancetype)init {
    self = [super init];
    if (self) {
        _opMode = OpModeNull;
        
        _softApSecurity = SoftAPSecurityUnknown;
        _softApConnectionCount = -1;
        _softApMaxConnection = -1;
        _softApChannel = -1;
        _softApSsid = nil;
        _softApPassword = nil;
        
        _staConnectionStatus = -1;
        _staBssid = nil;
        _staSsid = nil;
        _staPassword = nil;
    }
    return self;
}

- (BOOL)isStaConnectWiFi {
    return _staConnectionStatus == 0;
}

- (NSString *)getStatusInfo {
    NSMutableString *info = [[NSMutableString alloc] init];
    [info appendString:@"OpMode: "];
    switch (_opMode) {
        case OpModeNull:
            [info appendString:@"NULL"];
            break;
        case OpModeSta:
            [info appendString:@"Station"];
            break;
        case OpModeSoftAP:
            [info appendString:@"SoftAP"];
            break;
        case OpModeStaSoftAP:
            [info appendString:@"Station/SoftAP"];
            break;
        default:
            break;
    }
    [info appendString:@"\n"];
    
    if (_opMode == OpModeSta || _opMode == OpModeStaSoftAP) {
        if ([self isStaConnectWiFi]) {
            [info appendString:@"Station connect Wi-Fi now"];
        } else {
            [info appendString:@"Station disconnect Wi-Fi now"];
        }
        [info appendString:@"\n"];
        if (_staBssid) {
            [info appendString:@"Station connect Wi-Fi bssid: "];
            [info appendString:_staBssid];
            [info appendString:@"\n"];
        }
        if (_staSsid) {
            [info appendString:@"Station connect Wi-Fi ssid: "];
            [info appendString:_staSsid];
            [info appendString:@"\n"];
        }
        if (_staPassword) {
            [info appendString:@"Statison connect Wi-Fi password: "];
            [info appendString:_staPassword];
            [info appendString:@"\n"];
        }
    }
    if (_opMode == OpModeSoftAP || _opMode == OpModeStaSoftAP) {
        switch (_softApSecurity) {
            case SoftAPSecurityOpen:
                [info appendString:@"SoftAP security: OPEN\n"];
                break;
            case SoftAPSecurityWEP:
                [info appendString:@"SoftAP security: WEP\n"];
                break;
            case SoftAPSecurityWPA:
                [info appendString:@"SoftAP security: WPA\n"];
                break;
            case SoftAPSecurityWPA2:
                [info appendString:@"SoftAP security: WPA2\n"];
                break;
            case SoftAPSecurityWPAWPA2:
                [info appendString:@"SoftAP security: WPA/WPA2\n"];
                break;
            case SoftAPSecurityUnknown:
                break;
        }
        
        if (_softApSsid) {
            [info appendString:@"SoftAP ssid: "];
            [info appendString:_softApSsid];
            [info appendString:@"\n"];
        }
        if (_softApPassword) {
            [info appendString:@"SoftAP password: "];
            [info appendString:_softApPassword];
            [info appendString:@"\n"];
        }
        if (_softApChannel >= 0) {
            [info appendFormat:@"SoftAP channel: %d\n", _softApChannel];
        }
        if (_softApMaxConnection >= 0) {
            [info appendFormat:@"SoftAP max connection: %d\n", _softApMaxConnection];
        }
        if (_softApConnectionCount >= 0) {
            [info appendFormat:@"SoftAP current connection: %d\n", _softApConnectionCount];
        }
    }
   
    return info;
}

@end
