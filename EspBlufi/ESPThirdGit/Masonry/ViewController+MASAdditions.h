//
//  UIViewController+MASAdditions.h
//  Masonry
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//
//

#import "MASUtilities.h"
#import "MASConstraintMaker.h"
#import "MASViewAttribute.h"

#ifdef MAS_VIEW_CONTROLLER

@interface MAS_VIEW_CONTROLLER (MASAdditions)

/**
 *	following properties return a new MASViewAttribute with appropriate UILayoutGuide and NSLayoutAttribute
 */
@property (nonatomic, strong, readonly) MASViewAttribute *mas_topLayoutGuide;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_bottomLayoutGuide;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_topLayoutGuideTop;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_topLayoutGuideBottom;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_bottomLayoutGuideTop;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_bottomLayoutGuideBottom;


@end

#endif
