//
//  NSArray+MASShorthandAdditions.h
//  Masonry
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import "NSArray+MASAdditions.h"

#ifdef MAS_SHORTHAND

/**
 *	Shorthand array additions without the 'mas_' prefixes,
 *  only enabled if MAS_SHORTHAND is defined
 */
@interface NSArray (MASShorthandAdditions)

- (NSArray *)makeConstraints:(void(^)(MASConstraintMaker *make))block;
- (NSArray *)updateConstraints:(void(^)(MASConstraintMaker *make))block;
- (NSArray *)remakeConstraints:(void(^)(MASConstraintMaker *make))block;

@end

@implementation NSArray (MASShorthandAdditions)

- (NSArray *)makeConstraints:(void(^)(MASConstraintMaker *))block {
    return [self mas_makeConstraints:block];
}

- (NSArray *)updateConstraints:(void(^)(MASConstraintMaker *))block {
    return [self mas_updateConstraints:block];
}

- (NSArray *)remakeConstraints:(void(^)(MASConstraintMaker *))block {
    return [self mas_remakeConstraints:block];
}

@end

#endif
