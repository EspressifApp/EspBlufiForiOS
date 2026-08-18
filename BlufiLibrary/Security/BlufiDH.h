//
//  BlufiDH.h
//  EspBlufi
//
//  Created by AE on 2020/6/10.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlufiDH : NSObject

@property(strong, nonatomic, readonly)NSData *p;
@property(strong, nonatomic, readonly)NSData *g;
@property(strong, nonatomic, readonly)NSData *publicKey;
@property(strong, nonatomic, readonly)NSData *privateKey;

- (instancetype)initWithP:(NSData *)p G:(NSData *)g PublicKey:(NSData *)publicKey PrivateKey:(NSData *)privateKey;

- (NSData *)generateSecret:(NSData *)privateKey;

- (void)releaseDH;

@end

NS_ASSUME_NONNULL_END
