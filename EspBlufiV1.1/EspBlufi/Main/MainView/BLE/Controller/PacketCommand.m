//
//  PacketCommand.m
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import "PacketCommand.h"
#import "Prefix.pch"
#import "RSAObject.h"
#import "DH_AES.h"


@implementation PacketCommand

 int CRC16_TABLE[256]= {
    0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7, 0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
    0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6, 0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
    0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485, 0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
    0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4, 0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
    0x48c4, 0x58e5, 0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823, 0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
    0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50, 0x3a33, 0x2a12, 0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
    0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41, 0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
    0x7e97, 0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70, 0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78,
    0x9188, 0x81a9, 0xb1ca, 0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f, 0x1080, 0x00a1, 0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
    0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c, 0xe37f, 0xf35e, 0x02b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214, 0x6277, 0x7256,
    0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d, 0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
    0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c, 0x26d3, 0x36f2, 0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
    0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab, 0x5844, 0x4865, 0x7806, 0x6827, 0x18c0, 0x08e1, 0x3882, 0x28a3,
    0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a, 0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1, 0x1ad0, 0x2ab3, 0x3a92,
    0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b, 0x9de8, 0x8dc9, 0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0x0cc1,
    0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8, 0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0
};
//对比校验值
+(BOOL)VerifyCRCWithData:(NSData *)data
{
    int crc=0;
    Byte *pByte=(Byte *)[data bytes];
    
    crc = ~(crc & 0xffff);
    for (int i = 2; i < data.length-2; i++) {
        crc = CRC16_TABLE[((crc & 0xffff) >> 8) ^ (pByte[i] & 0xff)] ^ ((crc & 0xffff) << 8);
    }
    int value=~(crc & 0xffff);
    NSData *valuedata=[NSData dataWithBytes:&value length:2];
    if ([valuedata isEqual:[data subdataWithRange:NSMakeRange(data.length-2, 2)]]) {
        return YES;
    }else
    {
        return NO;
    }
}
//得到校验值
+(NSData *)GetCRCWithData:(NSData *)data
{
    int crc=0;
    Byte *pByte=(Byte *)[data bytes];
    
    crc = ~(crc & 0xffff);
    for (int i = 2; i < data.length; i++) {
        crc = CRC16_TABLE[((crc & 0xffff) >> 8) ^ (pByte[i] & 0xff)] ^ ((crc & 0xffff) << 8);
    }
    int value=~(crc & 0xffff);
    NSData *valuedata=[NSData dataWithBytes:&value length:2];
    return valuedata;
}
//16进制字符串转nadata
+(NSData *)convertHexStrToData:(NSString *)str {
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}


//生成加密对象
+(NSData *)GenerateNegotiateData:(RSAObject *)rsaobject
{
    uint16_t Plength=rsaobject.P.length;
    uint16_t Glength=rsaobject.g.length;
    uint16_t Publickeylength=rsaobject.PublickKey.length;
    
    uint8_t plengthC[2],GlengthC[2],plubickeylengthC[2];
    
    plengthC[0]=(uint8_t)(Plength>>8);
    plengthC[1]=(uint8_t)(Plength&0x00ff);
    
    GlengthC[0]=(uint8_t)(Glength>>8);
    GlengthC[1]=(uint8_t)(Glength&0x00ff);
    
    plubickeylengthC[0]=(uint8_t)(Publickeylength>>8);
    plubickeylengthC[1]=(uint8_t)(Publickeylength&0x00ff);
    
    //长度
    NSData *Plengthdata=[NSMutableData dataWithBytes:&plengthC length:sizeof(Plength)];
    NSData *Qlengthdata=[NSMutableData dataWithBytes:&GlengthC length:sizeof(Glength)];
    
    NSData *publiclenthdata=[NSMutableData dataWithBytes:&plubickeylengthC length:sizeof(plubickeylengthC)];
    
    NSData *Pdata=rsaobject.P;
    
    NSData *Qdata=rsaobject.g;
    
    NSData *publickeydata=rsaobject.PublickKey;
    
    
    uint8_t datatype[1]={0x01};
    NSMutableData *RSAdata=[NSMutableData dataWithBytes:&datatype length:sizeof(datatype)];
    [RSAdata appendData:Plengthdata];
    [RSAdata appendData:Pdata];
    [RSAdata appendData:Qlengthdata];
    [RSAdata appendData:Qdata];
    [RSAdata appendData:publiclenthdata];
    [RSAdata appendData:publickeydata];
    //zwjLog(@"RSAdata=%@,len=%ld",RSAdata,RSAdata.length);
    return RSAdata;
}


/*************************************** 控制包 *********************************************/
//回复ACK
+(NSMutableData *)ReturnAckWithSequence:(uint8_t)sequence BackSequence:(uint8_t)backsequence;
{
    uint8_t dataByte[5];
    dataByte[0]=(0x00<<2) | 0x00; //控制包，设置 ConnectToAP
    dataByte[1]=0x08;             //不加密,无校验,手机发,没有后续包,有ACK
    dataByte[2]=sequence;         //序列
    dataByte[3]=0x01;
    dataByte[4]=backsequence;
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    return data;
    
}
//通知设备安全模式
+(NSMutableData *)SetESP32ToPhoneSecurityWithSecurity:(BOOL)security CheckSum:(BOOL)checksum Sequence:(uint8_t)sequence
{
    uint8_t checksumbit=0x00;
    uint8_t securitybit=0x00;
    if (checksum) {
        checksumbit=0x01;
    }
    if (security) {
        securitybit=0x02;
    }
    uint8_t dataByte[5];
    dataByte[0]=(0x01<<2) | 0x00;             //控制包，通知加密方式
    dataByte[1]=0x00 | 0x02;                  //不加密,有校验,手机发,没有后续包,无ACK
    dataByte[2]=sequence;                     //序列
    dataByte[3]=0x01;                         //data length
    dataByte[4]=(checksumbit|securitybit);    //data
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    //加校验
    [data appendData:[self GetCRCWithData:data]];
    return data;
    
}

//设置Opmode
+(NSMutableData *)SetOpmode:(Opmode)opmode Sequence:(uint8_t)sequence
{
    uint8_t dataByte[5];
    dataByte[0]=(0x02<<2) | 0x00; //控制包，设置Opmode
    dataByte[1]=0x00 | 0x02;      //不加密,有校验,手机发,没有后续包,无ACK
    dataByte[2]=sequence;         //序列
    dataByte[3]=0x01;             //data length
    dataByte[4]=opmode;             //opmode null
    zwjLog(@"Sequence=%d",sequence);
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    //加校验
    [data appendData:[self GetCRCWithData:data]];
    return data;
}

//连接AP
+(NSMutableData *)ConnectToAPWithSequence:(uint8_t)sequence
{
    uint8_t dataByte[3];
    dataByte[0]=(0x03<<2) | 0x00; //控制包，设置 ConnectToAP
    dataByte[1]=0x00;             //不加密,无校验,手机发,没有后续包,无ACK
    dataByte[2]=sequence;         //序列
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    return data;
    
}
//断开连接AP
+(NSMutableData *)DisconnectFromAPWithSequence:(uint8_t)sequence
{
    uint8_t dataByte[3];
    dataByte[0]=(0x04<<2) | 0x00; //控制包，设置 DisconnectFromAP
    dataByte[1]=0x00;             //不加密,无校验,手机发,没有后续包,无ACK
    dataByte[2]=sequence;         //序列
    //dataByte[3]=0x00;             //checksum
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    return data;
    
}

//获取wifi信息
+(NSMutableData *)GetDeviceInforWithSequence:(uint8_t)Sequence
{
    uint8_t dataByte[3];
    dataByte[0]=(0x05<<2) | 0x00; //控制包，获取wifi信息
    dataByte[1]=0x01;             //不加密,无校验,手机发,没有后续包,无ACK
    dataByte[2]=Sequence;         //序列
    //dataByte[3]=0x00;           //checksum
    zwjLog(@"Sequence=%d",Sequence);
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    return data;
}

+(NSMutableData *)DisconnectBLEWithSequence:(uint8_t)Sequence
{
    uint8_t dataByte[3];
    dataByte[0]=(0x08<<2) | 0x00; //控制包，获取wifi信息
    dataByte[1]=0x01;             //不加密,无校验,手机发,没有后续包,无ACK
    dataByte[2]=Sequence;         //序列
    //dataByte[3]=0x00;           //checksum
    zwjLog(@"Sequence=%d",Sequence);
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    return data;
}

//Wifi list
+(NSMutableData *)GetWifiListWithSequence:(uint8_t)Sequence
{
    uint8_t dataByte[3];
    dataByte[0]=(0x09<<2) | 0x00; //控制包，获取wifi信息
    dataByte[1]=0x01;             //不加密,无校验,手机发,没有后续包,无ACK
    dataByte[2]=Sequence;         //序列
    //dataByte[3]=0x00;           //checksum
    zwjLog(@"Sequence=%d",Sequence);
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    return data;
}


/******************************* 数据包 *************************************/

//协商加密数据长度
+(NSMutableData *)SetNegotiatelength:(uint16_t)length Sequence:(uint8_t)sequence
{
    uint8_t dataByte[7];
    dataByte[0]=(0x00<<2) | 0x01;             //数据包，协商加密方式
    dataByte[1]=0x00 | 0x02;                  //不加密,有校验,手机发,没有后续包,无ACK
    dataByte[2]=sequence;                     //序列
    dataByte[3]=0x03;                         //data length
    dataByte[4]=0x00;                         //data type
    dataByte[5]=(uint8_t)(length>>8);         //data length Hbit
    dataByte[6]=(uint8_t)(length&0x00ff);     //dat length Lbit
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    
    //加校验
    [data appendData:[self GetCRCWithData:data]];
    return data;
}

//协商加密数据内容
+(NSData *)SendNegotiateData:(NSData *)somedata Sequence:(uint8_t)sequence Frag:(BOOL)flag TotalLength:(uint16_t)totallength
{
    
    if (flag) {
        uint8_t dataByte[6];
        dataByte[0]=(0x00<<2) | 0x01;             //数据包，协商加密方式
        dataByte[1]=0x10 | 0x02;                         //不加密,无校验,手机发,有后续包,无ACK
        dataByte[2]=sequence;                     //序列
        dataByte[3]=somedata.length+2;            //data length
        dataByte[4]=(uint8_t)(totallength&0x00ff);
        dataByte[5]=(uint8_t)(totallength>>8);
        //zwjLog(@"sizeof(dataByte)=%ld",sizeof(dataByte));
        NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
        [data appendData:somedata];
        //加校验
        [data appendData:[self GetCRCWithData:data]];
        
        return data;
    }else
    {
        uint8_t dataByte[4];
        dataByte[0]=(0x00<<2) | 0x01;             //数据包，协商加密方式
        dataByte[1]=0x00 | 0x02;                         //不加密,无校验,手机发,无后续包,无ACK
        dataByte[2]=sequence;                     //序列
        dataByte[3]=somedata.length;            //data length
        //zwjLog(@"sizeof(dataByte)=%ld",sizeof(dataByte));
        NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
        [data appendData:somedata];
        //加校验
        [data appendData:[self GetCRCWithData:data]];
        return data;
    }
}


//设置STA模式的ssid
+(NSMutableData *)SetStationSsid:(NSString *)ssid  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata
{
    NSData *Ssiddata=[ssid dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t dataByte[4];
    dataByte[0]=(0x02<<2) | 0x01;            //数据包，设置Opmode
    if (Isencrypt) {
        dataByte[1]=0x01 | 0x02;             //加密,有校验,手机发,没有后续包,无ACK
    }else
    {
         dataByte[1]=0x00 | 0x02;             //不加密,有校验,手机发,没有后续包,无ACK
    }
    dataByte[2]=sequence;                     //序列
    dataByte[3]=Ssiddata.length;                  //data length
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    
    //计算校验码
    NSMutableData *Tempdata=[NSMutableData dataWithData:data];
    [Tempdata appendData:Ssiddata];
    NSData *checksumdata=[self GetCRCWithData:Tempdata];
    //加密
    if (Isencrypt) {
        Byte *byte=(Byte *)[Ssiddata bytes];
        
        Ssiddata=[DH_AES blufi_aes_Encrypt:dataByte[2] data:byte len:(int)Ssiddata.length KeyData:keydata];
    }
    //拼接
    [data appendData:Ssiddata];
    //加校验
    [data appendData:checksumdata];
    
    return data;
}
//设置STA模式password
+(NSMutableData *)SetStationPassword:(NSString *)password  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata
{
    
    uint8_t dataByte[4];
    dataByte[0]=(0x03<<2) | 0x01;            //数据包，设置Opmode
    if(Isencrypt)
    {
        dataByte[1]=0x01 | 0x02;             //加密,有校验,手机发,没有后续包,无ACK
    }else
    {
        dataByte[1]=0x00 | 0x02;             //不加密,有校验,手机发,没有后续包,无ACK
    }
    dataByte[2]=sequence;                    //序列
    dataByte[3]=password.length;             //data length
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    NSData *passworddata=[password dataUsingEncoding:NSUTF8StringEncoding];
    
    //计算校验码
    NSMutableData *Tempdata=[NSMutableData dataWithData:data];
    [Tempdata appendData:passworddata];
    NSData *checksumdata=[self GetCRCWithData:Tempdata];
    //加密
    if (Isencrypt) {
        Byte *byte=(Byte *)[passworddata bytes];
        passworddata=[DH_AES blufi_aes_Encrypt:dataByte[2] data:byte len:(int)password.length KeyData:keydata];
    }
    //拼接
    [data appendData:passworddata];
    
    //加校验码
    [data appendData:checksumdata];
    
    return data;
}

//设置SoftAP模式的ssid
+(NSMutableData *)SetSoftAPSsid:(NSString *)ssid  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata
{
    NSData *Ssiddata=[ssid dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t dataByte[4];
    dataByte[0]=(0x04<<2) | 0x01;             //数据包，设置ssid
    if(Isencrypt)
    {
        dataByte[1]=0x01 | 0x02;             //加密,有校验,手机发,没有后续包,无ACK
    }else
    {
        dataByte[1]=0x00 | 0x02;             //不加密,有校验,手机发,没有后续包,无ACK
    }
    dataByte[2]=sequence;                    //序列
    dataByte[3]=Ssiddata.length;                 //data length
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    
    //计算校验码
    NSMutableData *Tempdata=[NSMutableData dataWithData:data];
    [Tempdata appendData:Ssiddata];
    NSData *checksumdata=[self GetCRCWithData:Tempdata];
    //加密
    if (Isencrypt) {
        Byte *byte=(Byte *)[Ssiddata bytes];
        Ssiddata=[DH_AES blufi_aes_Encrypt:dataByte[2] data:byte len:(int)Ssiddata.length KeyData:keydata];
    }

    //拼接
    [data appendData:Ssiddata];
    
    //加校验码
    [data appendData:checksumdata];
    return data;
}
//设置SoftAP模式password
+(NSMutableData *)SetSoftAPPassword:(NSString *)password  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata
{
    
    uint8_t dataByte[4];
    dataByte[0]=(0x05<<2) | 0x01;              //数据包，设置password
    if(Isencrypt)
    {
        dataByte[1]=0x01 | 0x02 ;             //加密,有校验,手机发,没有后续包,无ACK
    }else
    {
        dataByte[1]=0x00 | 0x02 ;             //不加密,有校验,手机发,没有后续包,无ACK
    }
    dataByte[2]=sequence;                     //序列
    dataByte[3]=password.length;             //data length
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    NSData *passworddata=[password dataUsingEncoding:NSUTF8StringEncoding];
    
    //计算校验码
    NSMutableData *Tempdata=[NSMutableData dataWithData:data];
    [Tempdata appendData:passworddata];
    NSData *checksumdata=[self GetCRCWithData:Tempdata];
    //加密
    if (Isencrypt) {
        Byte *byte=(Byte *)[passworddata bytes];
        passworddata=[DH_AES blufi_aes_Encrypt:dataByte[2] data:byte len:(int)password.length KeyData:keydata];
    }
    //拼接
    [data appendData:passworddata];
    //加校验码
    [data appendData:checksumdata];
    
    return data;
}

//设置softAP 的 Max connection
+(NSMutableData *)SetMaxConnectforSoftAP:(uint8_t)max  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata
{
    if (max>4 || max<=0) {
        max=4;
    }
    uint8_t dataByte[5];
    dataByte[0]=(0x06<<2) | 0x01;     //数据包，设置 Max connection
    if (Isencrypt) {
        dataByte[1]=0x01 | 0x02;      //加密,有校验,手机发,没有后续包,无ACK
    }else
    {
        dataByte[1]=0x00 | 0x02;      //不加密,有校验,手机发,没有后续包,无ACK
    }
    
    dataByte[2]=sequence;         //序列
    dataByte[3]=0x01;             //data length
    dataByte[4]=max;              //data
    
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    //加校验
    [data appendData:[self GetCRCWithData:data]];
    if (Isencrypt) {
        //加密
        NSData *hh=[DH_AES blufi_aes_Encrypt:dataByte[2] data:&dataByte[4] len:1 KeyData:keydata];
        [data replaceBytesInRange:NSMakeRange(4, 1) withBytes:[hh bytes]];
    }
    
    
    return data;
}

//设置softAP 的Security
+(NSMutableData *)SetAuthenticationforSoftAP:(AuthenticationMode)mode  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata
{
    
    uint8_t dataByte[5];
    dataByte[0]=(0x07<<2) | 0x01;            //数据包，设置security
    if (Isencrypt) {
        dataByte[1]=0x01 | 0x02;             //加密,有校验,手机发,没有后续包,无ACK
    }else
    {
         dataByte[1]=0x00 | 0x02;            //不加密,有校验,手机发,没有后续包,无ACK
    }
   
    dataByte[2]=sequence;                //序列
    dataByte[3]=0x01;                    //data length
    dataByte[4]=mode;                    //data
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    //加校验
    [data appendData:[self GetCRCWithData:data]];
    
    if (Isencrypt) {
        //加密
        NSData *hh=[DH_AES blufi_aes_Encrypt:dataByte[2] data:&dataByte[4] len:1 KeyData:keydata];
        [data replaceBytesInRange:NSMakeRange(4, 1) withBytes:[hh bytes]];
    }
    return data;
}


//设置softAP 的 Channel
+(NSMutableData *)SetChannelforSoftAP:(uint8_t)channel  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata
{
    if (channel>14 || channel<=0) {
        channel=14;
    }
    uint8_t dataByte[5];
    dataByte[0]=(0x08<<2) | 0x01;       //数据包，设置channel
    if (Isencrypt) {
         dataByte[1]=0x01 | 0x02;       //加密,有校验,手机发,没有后续包,无ACK
    }else
    {
         dataByte[1]=0x00 | 0x02;       //不加密,有校验,手机发,没有后续包,无ACK
    }
    dataByte[2]=sequence;              //序列
    dataByte[3]=0x01;                  //data length
    dataByte[4]=channel;               //data
    NSMutableData *data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
    //加校验
    [data appendData:[self GetCRCWithData:data]];
    
    if (Isencrypt) {
        //加密
        NSData *hh=[DH_AES blufi_aes_Encrypt:dataByte[2] data:&dataByte[4] len:1 KeyData:keydata];
        [data replaceBytesInRange:NSMakeRange(4, 1) withBytes:[hh bytes]];
    }
    
    return data;
}

//send custom data
+ (NSMutableData *)SendCustomData:(NSData *)custom_data Sequence:(uint8_t)sequence Frag:(BOOL)flag Encrypt:(BOOL)Isencrypt TotalLength:(uint16_t)totallength WithKeyData:(NSData *)keydata
{
    NSMutableData *data=[[NSMutableData alloc] initWithCapacity:0];
    if (flag) {
        uint8_t dataByte[4];
        dataByte[0]=(0x13<<2) | 0x01;            //数据包，发送custom data
        if(Isencrypt)
        {
            dataByte[1]=0x01 | 0x02 | 0x00 | 0x00 | 0x10;             //加密,有校验,手机发,有后续包,无ACK
        }else
        {
            dataByte[1]=0x00 | 0x02 | 0x00 | 0x00 | 0x10;             //不加密,有校验,手机发,有后续包,无ACK
        }
        dataByte[2]=sequence;                    //序列
        dataByte[3]=custom_data.length+2;             //data length
        data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
        //NSData *customdata=[custom_data_str dataUsingEncoding:NSUTF8StringEncoding];
        
        Byte totalLengthByte[] = {(totallength&0x00ff),(totallength>>8)};
        NSMutableData* contentData=[NSMutableData dataWithCapacity:0];
        [contentData appendData:[[NSData alloc] initWithBytes:totalLengthByte length:2]];
        [contentData appendData:custom_data];
        
        //计算校验码
        NSMutableData *Tempdata=[NSMutableData dataWithData:data];
        [Tempdata appendData:contentData];
        NSData *checksumdata=[self GetCRCWithData:Tempdata];
        //加密
        if (Isencrypt) {
            Byte *byte=(Byte *)[contentData bytes];
            NSData* tmpCryptData=[DH_AES blufi_aes_Encrypt:sequence data:byte len:(int)contentData.length KeyData:keydata];
            contentData=[NSMutableData dataWithData:tmpCryptData];
        }
        //拼接
        [data appendData:contentData];
        
        //加校验码
        [data appendData:checksumdata];
        
        return data;
    }else {
        uint8_t dataByte[4];
        dataByte[0]=(0x13<<2) | 0x01;            //数据包，发送custom data
        if(Isencrypt)
        {
            dataByte[1]=0x01 | 0x02 | 0x00 | 0x00 | 0x00;             //加密,有校验,手机发,没有后续包,无ACK
        }else
        {
            dataByte[1]=0x00 | 0x02 | 0x00 | 0x00 | 0x00;             //不加密,有校验,手机发,没有后续包,无ACK
        }
        dataByte[2]=sequence;                    //序列
        dataByte[3]=custom_data.length;             //data length
        data=[NSMutableData dataWithBytes:&dataByte length:sizeof(dataByte)];
        //NSData *customdata=[custom_data_str dataUsingEncoding:NSUTF8StringEncoding];
        
        //计算校验码
        NSMutableData *Tempdata=[NSMutableData dataWithData:data];
        [Tempdata appendData:custom_data];
        NSData *checksumdata=[self GetCRCWithData:Tempdata];
        //加密
        if (Isencrypt) {
            Byte *byte=(Byte *)[custom_data bytes];
            custom_data=[DH_AES blufi_aes_Encrypt:dataByte[2] data:byte len:(int)custom_data.length KeyData:keydata];
        }
        //拼接
        [data appendData:custom_data];
        
        //加校验码
        [data appendData:checksumdata];
        
        return data;
    }
    
}

@end
