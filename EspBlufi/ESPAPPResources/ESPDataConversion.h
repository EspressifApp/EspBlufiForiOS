//
//  ESPDataConversion.h
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/12.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPDataConversion : NSObject

/**
 keychain存

 @param value 要存的对象的key值
 @param key 要保存的value值
 @return 保存结果
 */
+ (BOOL)fby_saveNSUserDefaults:(id)value withKey:(NSString *)key;

/**
 keychain取

 @param key 对象的key值
 @return 获取的对象
 */
+ (id)fby_getNSUserDefaults:(NSString *)key;

+ (BOOL)saveBlufiScanFilter:(NSString *)filter;

+ (NSString *)loadBlufiScanFilter;
@end

NS_ASSUME_NONNULL_END
