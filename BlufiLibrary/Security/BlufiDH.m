//
//  BlufiDH.m
//  EspBlufi
//
//  Created by AE on 2020/6/10.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "BlufiDH.h"
#import "BlufiDHEngine.h"

@implementation BlufiDH

- (instancetype)initWithP:(NSData *)p G:(NSData *)g PublicKey:(NSData *)publicKey PrivateKey:(NSData *)privateKey {
    self = [super init];
    if (self) {
        _p = p;
        _g = g;
        _publicKey = publicKey;
        _privateKey = privateKey;
    }
    return self;
}

- (NSData *)generateSecret:(NSData *)srcPublicKey {
    if (!_p || !_privateKey || !srcPublicKey || srcPublicKey.length == 0) {
        NSLog(@"BlufiDH: invalid parameters");
        return nil;
    }

    uint8_t out[BLUFI_DH_MAX_BYTES];
    size_t secretLength = blufi_dh_compute_secret(_p.bytes, _p.length,
                                                  _privateKey.bytes, _privateKey.length,
                                                  srcPublicKey.bytes, srcPublicKey.length,
                                                  out);
    if (secretLength == 0) {
        NSLog(@"BlufiDH: compute secret failed");
        return nil;
    }
    return [NSData dataWithBytes:out length:secretLength];
}

- (void)releaseDH {
    // No-op: the local implementation holds no external resources to release.
}

@end
