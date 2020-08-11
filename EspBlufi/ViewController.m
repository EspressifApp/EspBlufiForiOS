//
//  ViewController.m
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "ESPPeripheral.h"
#import "FFDropDownMenuView.h"
#import "MJRefresh.h"
#import "ESPSettingViewController.h"
#import "ESPDetailViewController.h"
#import "ESPFBYBLEHelper.h"
#import "ESPDataConversion.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic, strong) FFDropDownMenuView *dropDownMenu;
@property(nonatomic, strong) UITableView *peripheralView;
@property(nonatomic, copy)   NSMutableArray<ESPPeripheral *> *peripheralArray;
@property(nonatomic, strong) ESPFBYBLEHelper *espFBYBleHelper;
@property(nonatomic, strong) NSString *filterContent;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.espFBYBleHelper = [ESPFBYBLEHelper share];
    self.navigationItem.title = INTER_STR(@"EspBlufi-nav-title");
//    UIButton *menuBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
//    [menuBtn addTarget:self action:@selector(showDropDownMenu) forControlEvents:UIControlEventTouchUpInside];
//    [menuBtn setImage:[UIImage imageNamed:@"more"] forState:UIControlStateNormal];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuBtn];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showDropDownMenu)];
    NSArray *modelsArray = [self getMenuModelsArray];
    self.dropDownMenu = [FFDropDownMenuView ff_DefaultStyleDropDownMenuWithMenuModelsArray:modelsArray menuWidth:140 eachItemHeight:50 menuRightMargin:FFDefaultFloat triangleRightMargin:FFDefaultFloat];
    [self setupBasedView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.filterContent = [ESPDataConversion loadBlufiScanFilter];
    [self scanDeviceInfo];
}

- (void)scanDeviceInfo {
    NSLog(@"vc 扫描设备");
    [self.dataSource removeAllObjects];
    [self.espFBYBleHelper startScan:^(ESPPeripheral * _Nonnull device) {
        if ([self shouldAddToSource:device]) {
            [self.dataSource addObject:device];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.peripheralView reloadData];
            });
        }
    }];
}

- (NSArray *)getMenuModelsArray {
    __weak typeof(self) weakSelf = self;
    FFDropDownMenuModel *menuModel0 = [FFDropDownMenuModel ff_DropDownMenuModelWithMenuItemTitle:INTER_STR(@"EspBlufi-Setting") menuItemIconName:nil  menuBlock:^{
        ESPSettingViewController *svc = [ESPSettingViewController new];
        [weakSelf.navigationController pushViewController:svc animated:YES];
    }];
    NSArray *menuModelArr = @[menuModel0];
    return menuModelArr;
}

- (void)showDropDownMenu {
    [self.dropDownMenu showMenu];
}

- (void)setupBasedView {
    self.peripheralView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.peripheralView.delegate = self;
    self.peripheralView.dataSource = self;
    self.peripheralView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.peripheralView];
    self.peripheralView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(MJRefresh_header)];
}

- (void)MJRefresh_header{
    [self.peripheralView.mj_header beginRefreshing];
    [self scanDeviceInfo];
    sleep(3);
    [self.peripheralView.mj_header endRefreshing];
    [self.peripheralView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _peripheralArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    if (!ValidArray(_peripheralArray)) {
        return cell;
    }
    
    ESPPeripheral *device = _peripheralArray[indexPath.row];
    NSString *name = device.name;
    int rssi = device.rssi;
    NSString *uuid = device.uuid.UUIDString;
    
    UILabel *nameLab = [[UILabel alloc] init];
    nameLab.frame = CGRectMake(15, 0, CGRectGetWidth(tableView.frame), 40);
    NSString *deviceName = [NSString stringWithFormat:@"%@    %d", name, rssi];
    nameLab.text = deviceName;
    nameLab.font = [UIFont systemFontOfSize:16];
    [cell.contentView addSubview:nameLab];
    
    UILabel *uuidLab = [[UILabel alloc] init];
    uuidLab.frame = CGRectMake(15, 30,CGRectGetWidth(tableView.frame), 20);
    NSString *deviceInfo = [NSString stringWithFormat:@"%@",uuid];
    uuidLab.text = deviceInfo;
    uuidLab.textColor = [UIColor lightGrayColor];
    uuidLab.font = [UIFont systemFontOfSize:14];
    [cell.contentView addSubview:uuidLab];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (!ValidArray(_peripheralArray)) {
        return;
    }
    ESPDetailViewController *dvc = [ESPDetailViewController new];
    dvc.device = _peripheralArray[indexPath.row];
    [self.navigationController pushViewController:dvc animated:YES];
}

- (NSMutableArray *)dataSource {
    if (!_peripheralArray) {
        _peripheralArray = [[NSMutableArray alloc] init];
    }
    return _peripheralArray;
}

- (BOOL)shouldAddToSource:(ESPPeripheral *)device {
    NSArray *source = [self dataSource];
    // Check filter
    if (_filterContent && _filterContent.length > 0) {
        if (!device.name || ![device.name hasPrefix:_filterContent]) {
            // The device name has no filter prefix
            return NO;
        }
    }
    
    // Check exist
    for (int i = 0; i < source.count; i++) {
        ESPPeripheral *existDevice = source[i];
        if ([device.uuid isEqual:existDevice.uuid]) {
            // The device exists in source already
            return NO;
        }
    }
    
    return YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.espFBYBleHelper stopScan];
}
@end
