//
//  BLEdataFunc.h
//  EspBlufi
//
//  Created by zhi weijian on 16/7/27.
//  Copyright © 2016年 zhi weijian. All rights reserved.
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
