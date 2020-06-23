//
//  BlufiVersionResponse.h
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlufiVersionResponse : NSObject

@property(assign, nonatomic)Byte bigVer;
@property(assign, nonatomic)Byte smallVer;

- (NSString *)getVersionString;

@end

NS_ASSUME_NONNULL_END
