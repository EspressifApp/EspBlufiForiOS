//
//  PopView.h
//  popview
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <UIKit/UIKit.h>

@protocol PopViewDelegate <NSObject>

-(void)PopViewSelectIndex:(NSInteger)index;
-(void)HidePopView;
@end
@interface PopView : UIView

@property (weak, nonatomic) IBOutlet UILabel *titlelabel;

@property(nonatomic,strong)NSMutableArray *dataArray;
@property(nonatomic,weak)id<PopViewDelegate>popdelegate;

+(instancetype)instancePopView;

@end
