//
//  PopViewController.m
//  popview
//
//  Created by zhi weijian on 16/6/27.
//  Copyright © 2016年 zhi weijian. All rights reserved.
//

#import "PopView.h"
#import "BLEDevice.h"
#import "UIColor+Hex.h"

@interface PopView ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tabview;
@property (weak, nonatomic) IBOutlet UIButton *hideBtn;

@end

@implementation PopView

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self=[super initWithCoder:aDecoder]) {
        self.layer.cornerRadius=20;
        self.layer.masksToBounds=YES;
        self.layer.borderWidth=2;
        self.layer.borderColor=[UIColor lightGrayColor].CGColor;
        //self.backgroundColor=[UIColor colorWithRed:200/256.0 green:225/256.0 blue:225/256.0 alpha:1];
        self.tabview.backgroundColor=[UIColor clearColor];
    }
    return self;
}

+(instancetype)instancePopView
{
    NSArray *nibarray=[[NSBundle mainBundle] loadNibNamed:@"PopView" owner:self options:nil];
    return [nibarray objectAtIndex:0];
}
-(void)awakeFromNib
{
    [super awakeFromNib];
    [self.hideBtn setTitle:NSLocalizedString(@"hide", nil) forState:UIControlStateNormal];
    self.titlelabel.backgroundColor=[UIColor colorWithHexString:@"#7aC4Eb"];
    self.titlelabel.textColor=[UIColor whiteColor];
    self.hideBtn.backgroundColor=[UIColor colorWithHexString:@"#7aC4Eb"];
    [self.hideBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID=@"cell";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ID];
    }
    BLEDevice *device=self.dataArray[indexPath.row];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.textLabel.text=device.name;
    cell.detailTextLabel.text=NSLocalizedString(@"connect", nil);
    cell.detailTextLabel.textColor=[UIColor blueColor];
    return cell;
}

-(void)setDataArray:(NSMutableArray *)dataArray
{
    _dataArray=dataArray;
    [self.tabview reloadData];
    
}
- (IBAction)backViewClick:(UIButton *)sender {
    [self.superview removeFromSuperview];
    [self removeFromSuperview];
    
    if ([self.popdelegate respondsToSelector:@selector(HidePopView)]) {
        [self.popdelegate HidePopView];
    }
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //zwjLog(@"%s,%ld",__func__,indexPath.row);
    if ([self.popdelegate respondsToSelector:@selector(PopViewSelectIndex:)]) {
        [self.popdelegate PopViewSelectIndex:indexPath.row];
    }
    [self backViewClick:nil];
}
-(void)dealloc
{
    //Log(@"%s",__func__);
}
@end
