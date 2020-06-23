//
//  MASCompositeConstraint.h
//  Masonry
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import "MASConstraint.h"
#import "MASUtilities.h"

/**
 *	A group of MASConstraint objects
 */
@interface MASCompositeConstraint : MASConstraint

/**
 *	Creates a composite with a predefined array of children
 *
 *	@param	children	child MASConstraints
 *
 *	@return	a composite constraint
 */
- (id)initWithChildren:(NSArray *)children;

@end
