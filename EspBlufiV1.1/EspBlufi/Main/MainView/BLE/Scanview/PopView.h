//
//  PopView.h
//  popview
//
//  Created by zhi weijian on 16/6/27.
//  Copyright © 2016年 zhi weijian. All rights reserved.
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
