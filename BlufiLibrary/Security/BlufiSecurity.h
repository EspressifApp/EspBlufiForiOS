//
//  BlufiSecurity.h
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlufiDH.h"
#import <CommonCrypto/CommonCrypto.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlufiSecurity : NSObject

+ (NSInteger)crc:(NSInteger)crc data:(NSData *)data;

+ (NSInteger)crc:(NSInteger)crc buf:(Byte *)buf length:(NSInteger)length;

+ (NSData *)md5:(NSData *)data;

+ (NSData *)sha256:(NSData *)data;

+ (NSData *)aesEncrypt:(NSData *)data key:(NSData *)key iv:(NSData *)iv;

+ (NSData *)aesDecrypt:(NSData *)data key:(NSData *)key iv:(NSData *)iv;

/// First 16 bytes of SHA256(domainUTF8 + key). Used for SECURITY_V2 AES-CTR IV.
+ (NSData *)generateAESIV2WithDomain:(NSString *)domain key:(NSData *)key;

/// Create AES-CTR cryptor (caller must call CCCryptorRelease when done).
+ (CCCryptorRef)createAESCTRCryptorWithKey:(NSData *)key iv:(NSData *)iv encrypt:(BOOL)encrypt;

/// AES-CTR update (does not release cryptor). Used for SECURITY_V2 streaming.
+ (NSData *)aesCTRUpdateWithCryptor:(CCCryptorRef)cryptor data:(NSData *)data;

+ (BlufiDH *)dhGenerateKeys;

+ (BlufiDH *)dhGenerateKeysWithLength:(int)length;

@end

NS_ASSUME_NONNULL_END
