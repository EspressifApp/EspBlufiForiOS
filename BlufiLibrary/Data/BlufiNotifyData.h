//
//  BlufiNotifyData.h
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlufiConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlufiNotifyData : NSObject

@property(assign, nonatomic)Byte typeValue;
@property(assign, nonatomic)PackageType packageType;
@property(assign, nonatomic)SubType subType;

@property(assign, nonatomic)NSInteger frameCtrl;

- (void)appendData:(NSData *)data;

- (NSData *)getData;

@end

NS_ASSUME_NONNULL_END
