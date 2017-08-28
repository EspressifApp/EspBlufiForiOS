//
//  RSAObject.h
//  EspBlufi
//
//  Created by zhiweijian on 30/03/2017.
//  Copyright © 2017 zhi weijian. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <openssl/dh.h>
@interface RSAObject : NSObject

@property(nonatomic,strong)NSData *P;
@property(nonatomic,strong)NSData *g;
@property(nonatomic,copy)NSData *PublickKey;
@property(nonatomic,copy)NSData *PrivateKey;
@property(nonatomic,assign)DH *dh;

@end
