//
//  BLEdataFunc.m
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import "BLEdataFunc.h"
#import "BLEDevice.h"
#import "Prefix.pch"

@implementation BLEdataFunc

static BLEdataFunc *bledatafunc=nil;

//获取蓝牙广播中的序列号
+(NSString *)GetSerialNumber:(NSDictionary *)advertisementData
{
    NSData *ManufacturerData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    if (!ManufacturerData)
    {
        return nil;
    }
//    unsigned int CompanyID=[self BLEdataTOintWithData:ManufacturerData Locatoin:0 Offset:2];
//    if (CompanyID!=0x0326) {
//        return nil;
//    }
    NSData *serialnumberData=[ManufacturerData subdataWithRange:NSMakeRange(8, 6)];
    NSString *serialnumber=[[NSString alloc]initWithData:serialnumberData encoding:NSUTF8StringEncoding];
    //Log(@"serialnumberData = %@",serialnumber);
    return serialnumber;
}
//注意大小端
+(unsigned int)BLEdataTOintWithData:(NSData *)data Locatoin:(NSInteger)locate Offset:(NSInteger)offset
{
    unsigned int value=0;
    NSData *intdata= [data subdataWithRange:NSMakeRange(locate, offset)];
    
    // Log(@"%@ ",intdata);
    if (offset==2) {
        value=CFSwapInt16BigToHost(*(int*)([intdata bytes]));
    }
    else if (offset==4) {
        value = CFSwapInt32BigToHost(*(int*)([intdata bytes]));
    }
    else if (offset==1) {
        unsigned char *bs = (unsigned char *)[[data subdataWithRange:NSMakeRange(locate, 1) ] bytes];
        value = *bs;
    }
    //Log(@"%d",value);
    return value;
}
//温度数据有效判断,目前需要舍弃42℃以上的数据
+(BOOL)IsValidTempData:(unsigned int)temp
{
    if (temp >=4200 || temp <=100) {
        return NO;
    }
    return YES;
}
//取得最大值
+(unsigned int)GetMaxValueWithData1:(unsigned int)data1 WithData2:(unsigned int)data2
{
    BOOL Booltemp1=[self IsValidTempData:data1];
    BOOL Booltemp2=[self IsValidTempData:data2];
    if (Booltemp1 && Booltemp2)
    {
        if (data1>data2){
            return data1;
        }
        else{
            return data2;
        }
        
    }
    else
    {
        if (Booltemp1) {
            return data1;
        }
        else if (Booltemp2)
        {
            return data2;
        }
        else
        {
            return 0;
        }
    }
}
//是否蓝牙设备集合中已经存在(温度贴曾经连接过以后,广播信息在变化)
+(BOOL)isAleadyExist:(NSString*)str BLEDeviceArray:(NSMutableArray *)array
{
    NSInteger count=array.count;
    if (count==0) {
        return NO;
    }
    for (NSInteger i=0; i<count; i++) {
        BLEDevice *device=array[i];
        if ([str isEqualToString:device.name]) {
            return YES;
        }
    }
    return NO;
}
//大小端
+(signed int)SignedintBLEdataTOintWithData:(NSData *)data Locatoin:(NSInteger)locate Offset:(NSInteger)offset
{
    signed int value=0;
    NSData *intdata= [data subdataWithRange:NSMakeRange(locate, offset)];
    // Log(@"%@ ",intdata);
    if (offset==2) {
        value=CFSwapInt16BigToHost(*(int*)([intdata bytes]));
    }
    else if (offset==4) {
        value = CFSwapInt32BigToHost(*(int*)([intdata bytes]));
    }
    else if (offset==1) {
        signed char *bs = (signed char *)[[data subdataWithRange:NSMakeRange(locate, 1) ] bytes];
        value = *bs;
    }
    //Log(@"%d",value);
    return value;
}



@end
