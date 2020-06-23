//
//  BlufiDH.m
//  EspBlufi
//
//  Created by AE on 2020/6/10.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "BlufiDH.h"

@implementation BlufiDH

- (instancetype)initWithP:(NSData *)p G:(NSData *)g PublicKey:(NSData *)publicKey PrivateKey:(NSData *)privateKey DH:(nonnull DH *)dh {
    self = [super init];
    if (self) {
        _p = p;
        _g = g;
        _publicKey = publicKey;
        _privateKey = privateKey;
        _dh = dh;
    }
    return self;
}

- (NSData *)generateSecret:(NSData *)srcPublicKey {
    if (!_dh) {
        NSLog(@"BlufiDH: DH is nil");
        return nil;
    }
    Byte shareKey[128];
    BIGNUM *pubKey = BN_bin2bn(srcPublicKey.bytes, (int)srcPublicKey.length, NULL);
    int ret = 0;
    while (!ret) {
        ret = DH_compute_key(shareKey, pubKey, _dh);
    }
    BN_free(pubKey);
    return [NSData dataWithBytes:shareKey length:128];
}

- (void)releaseDH {
    if (_dh) {
        DH_free(_dh);
        _dh = nil;
    }
}

@end
