//
//  BLEdataFunc.h
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <Foundation/Foundation.h>

@interface BLEdataFunc : NSObject

+(NSString *)GetSerialNumber:(NSDictionary *)advertisementData;
+(unsigned int)BLEdataTOintWithData:(NSData *)data Locatoin:(NSInteger)locate Offset:(NSInteger)offset;
+(BOOL)IsValidTempData:(unsigned int)temp;
+(unsigned int)GetMaxValueWithData1:(unsigned int)data1 WithData2:(unsigned int)data2;
+(BOOL)isAleadyExist:(NSString*)str BLEDeviceArray:(NSArray *)array;
+(signed int)SignedintBLEdataTOintWithData:(NSData *)data Locatoin:(NSInteger)locate Offset:(NSInteger)offset;
@end
