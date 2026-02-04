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
    const int keySize = DH_size(_dh);
    Byte *shareKey = malloc(keySize);
    if (!shareKey) {
        NSLog(@"BlufiDH: Failed to allocate memory for shareKey");
        return nil;
    }
    
    BIGNUM *pubKey = BN_bin2bn(srcPublicKey.bytes, (int)srcPublicKey.length, NULL);
    int ret = 0;
    while (!ret) {
        ret = DH_compute_key(shareKey, pubKey, _dh);
    }
    BN_free(pubKey);
    
    int offset = 0;
    for (int i = 0; i < keySize; i++) {
        if (shareKey[i] == 0) {
            offset++;
        } else {
            break;
        }
    }
    
    NSData *result;
    if (offset == 0) {
        result = [NSData dataWithBytes:shareKey length:keySize];
    } else {
        int secretLength = keySize - offset;
        Byte *secretKey = malloc(secretLength);
        if (!secretKey) {
            free(shareKey);
            NSLog(@"BlufiDH: Failed to allocate memory for secretKey");
            return nil;
        }
        for (int i = 0; i < secretLength; i++) {
            secretKey[i] = shareKey[i + offset];
        }
        result = [NSData dataWithBytes:secretKey length:secretLength];
        free(secretKey);
    }
    free(shareKey);
    return result;
}

- (void)releaseDH {
    if (_dh) {
        DH_free(_dh);
        _dh = nil;
    }
}

@end
