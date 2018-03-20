//
//  DH_AES.m
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import "DH_AES.h"
#import "Prefix.pch"
#import <openssl/rsa.h>
#import <openssl/pem.h>
#import <openssl/dh.h>
#import <openssl/bn.h>
#import "PacketCommand.h"
#import <openssl/aes.h>
#import <openssl/md5.h>

@implementation DH_AES

+(RSAObject*)DHGenerateKey
{
    unsigned char data[] = {
        0xcf,0x5c,0xf5,0xc3,0x84,0x19,0xa7,0x24,0x95,0x7f,0xf5,0xdd,0x32,0x3b,0x9c,0x45,0xc3,0xcd,0xd2,0x61,0xeb,0x74,0x0f,0x69,0xaa,0x94,0xb8,0xbb,0x1a,0x5c,0x96,0x40,0x91,0x53,0xbd,0x76,0xb2,0x42,0x22,0xd0,0x32,0x74,0xe4,0x72,0x5a,0x54,0x06,0x09,0x2e,0x9e,0x82,0xe9,0x13,0x5c,0x64,0x3c,0xae,0x98,0x13,0x2b,0x0d,0x95,0xf7,0xd6,0x53,0x47,0xc6,0x8a,0xfc,0x1e,0x67,0x7d,0xa9,0x0e,0x51,0xbb,0xab,0x5f,0x5c,0xf4,0x29,0xc2,0x91,0xb4,0xba,0x39,0xc6,0xb2,0xdc,0x5e,0x8c,0x72,0x31,0xe4,0x6a,0xa7,0x72,0x8e,0x87,0x66,0x45,0x32,0xcd,0xf5,0x47,0xbe,0x20,0xc9,0xa3,0xfa,0x83,0x42,0xbe,0x6e,0x34,0x37,0x1a,0x27,0xc0,0x6f,0x7d,0xc0,0xed,0xdd,0xd2,0xf8,0x63,0x73 };
    
    DH *d1;
    int ret = 0,i;
    d1=DH_new();
    
    d1->p=BN_bin2bn(data, sizeof(data), NULL);
    d1->g=BN_new();
    BN_set_word(d1->g, 2);
    
    /* 生成公私钥 */
    while(!ret) {
        ret=DH_generate_key(d1);
    }
    /* 检查公钥 */
    ret=DH_check_pub_key(d1,d1->pub_key,&i);
    if(ret!=1) {
        zwjLog(@"error");
    }
    
    // 初始化
    RSAObject *rsaobject=[[RSAObject alloc]init];
    
    // P
    NSString *Phexstr=[NSString stringWithCString:BN_bn2hex(d1->p) encoding:NSUTF8StringEncoding];
    NSData *Pdata=[PacketCommand convertHexStrToData:Phexstr];
    rsaobject.P=Pdata;
    //zwjLog(@"%@",Phexstr);
    
    //G
    NSString *ghexstr=[NSString stringWithCString:BN_bn2hex(d1->g) encoding:NSUTF8StringEncoding];
    NSData *gdata=[PacketCommand convertHexStrToData:ghexstr];
    rsaobject.g=gdata;
    //zwjLog(@"%@,%ld",gdata,gdata.length);
    
    //publickey
    NSString *publickeystr=[NSString stringWithCString:BN_bn2hex(d1->pub_key) encoding:NSUTF8StringEncoding];
    NSData *publickeydata=[PacketCommand convertHexStrToData:publickeystr];
    rsaobject.PublickKey=publickeydata;
    //zwjLog(@"%@",publickeydata);
    rsaobject.dh=d1;
    
    return rsaobject;
    
}


+(NSData *)GetSecurtKey:(NSData *)DevicePublickkey RsaObject:(RSAObject *)object
{
    unsigned char sharekey[128];
    if (!object.dh) {
        zwjLog(@"秘钥不存在");
        return nil;
    }
    unsigned char MD5result[16];
    BIGNUM *pubkey=BN_new();
    Byte *byte=(Byte *)[DevicePublickkey bytes];
    pubkey=BN_bin2bn(byte, (int)DevicePublickkey.length, NULL);
    int ret = 0;
    while (!ret) {
       ret = DH_compute_key(sharekey, pubkey, object.dh);
    }
    
    BIGNUM *sharekeyBG=BN_new();
    sharekeyBG=BN_bin2bn(sharekey, sizeof(sharekey), NULL);
    MD5_CTX md5_ctx;
    MD5_Init(&md5_ctx);
    MD5_Update(&md5_ctx, sharekey, 128);
    MD5_Final(MD5result, &md5_ctx);
//    for (NSInteger i=0; i<16; i++) {
//        zwjLog(@"%02x,%ld,%@",MD5result[i],i,[NSString stringWithFormat:@"%02x",MD5result[i]]);
//       
//    }
    NSData *data=[NSData dataWithBytes:MD5result length:16];
    BN_free(pubkey);
    DH_free(object.dh);
    object.dh=NULL;
    zwjLog(@"security=%@",data);
    return data;
    
}

//加密
+(NSData *)blufi_aes_Encrypt:(uint8_t)sequence data:(uint8_t *)crypt_data len:(int) crypt_len KeyData:(NSData *)keydata
{
    unsigned char *MD5result=(Byte*)[keydata bytes];
    AES_KEY aes_key;
    
    AES_set_encrypt_key(MD5result, 128, &aes_key);
    
    int iv_offset = 0;
    uint8_t iv0[16]={0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
    iv0[0]=sequence;
    
    AES_cfb128_encrypt(crypt_data, crypt_data, crypt_len, &aes_key, iv0, &iv_offset, AES_ENCRYPT);
    
    NSData *Decrydata=[NSData dataWithBytes:crypt_data length:crypt_len];
    
    return Decrydata;
}
+(NSData *)blufi_aes_DecryptWithSequence:(uint8_t)sequence data:(uint8_t *)crypt_data len:(int)crypt_len KeyData:(NSData *)keydata
{
      unsigned char *MD5result=(Byte*)[keydata bytes];
//    for (NSInteger i=0; i<16; i++) {
//        zwjLog(@"%02x",MD5result[i]);
//    }
    
    AES_KEY aes_key;
    AES_set_encrypt_key(MD5result, 128, &aes_key);
    int iv_offset = 0;
    uint8_t iv0[16]={0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
    iv0[0]=sequence;
    
    AES_cfb128_encrypt(crypt_data, crypt_data, crypt_len, &aes_key, iv0, &iv_offset, AES_DECRYPT);
    
    //    for (NSInteger i=0; i<crypt_len; i++) {
    //        zwjLog(@"===%02x",crypt_data[i]);
    //    }
    NSData *Decrydata=[NSData dataWithBytes:crypt_data length:crypt_len];
    
    zwjLog(@"data=%@",Decrydata);
    return Decrydata;
    
}


@end
