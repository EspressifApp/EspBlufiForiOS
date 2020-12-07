//
//  ESPSettingViewController.m
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/10.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "ESPSettingViewController.h"
#import "ESPDataConversion.h"
#import "BlufiClient.h"

@interface ESPSettingViewController ()

@property(strong, nonatomic)NSString *filterStr;
@property(strong, nonatomic)NSString *appversion;
@property(strong, nonatomic)NSString *updateStr;
@property(strong, nonatomic)UILabel *filterContent;

@end

@implementation ESPSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.filterStr = @"BLUFI";
    self.appversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
//    self.appversion = @"1.0.0";
    self.updateStr = INTER_STR(@"EspBlufi-update-reminder");
    self.navigationItem.title = INTER_STR(@"EspBlufi-Setting");
    [self setupBasedView];
}

- (void)setupBasedView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, statusHeight + 44, SCREEN_WIDTH, 130)];
    [self.view addSubview:headerView];
    
    UILabel *headerTitle = [[UILabel alloc]initWithFrame:CGRectMake(15, 20, SCREEN_WIDTH - 20, 30)];
    headerTitle.textColor = UICOLOR_RGBA(141, 110, 99, 1);
    headerTitle.text = INTER_STR(@"EspBlufi-Setting-sign");
    [headerView addSubview:headerTitle];
    
    UILabel *filterName = [[UILabel alloc]initWithFrame:CGRectMake(15, 70, SCREEN_WIDTH - 20, 20)];
    filterName.text = INTER_STR(@"EspBlufi-Setting-filter");
    [filterName addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deviceFilter)]];
    filterName.userInteractionEnabled = YES;
    [headerView addSubview:filterName];
    
    self.filterContent = [[UILabel alloc]initWithFrame:CGRectMake(15, 90, SCREEN_WIDTH - 20, 20)];
    self.filterContent.textColor = [UIColor lightGrayColor];
    [self.filterContent addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deviceFilter)]];
    self.filterContent.userInteractionEnabled = YES;
    self.filterContent.font = [UIFont systemFontOfSize:16.0];
    NSString *filterText = [ESPDataConversion loadBlufiScanFilter];
    self.filterContent.text = filterText;
    [headerView addSubview:_filterContent];
    
    UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(0, 129, SCREEN_WIDTH, 1)];
    lab.backgroundColor = UICOLOR_RGBA(221, 221, 221, 1);
    [headerView addSubview:lab];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, statusHeight + 174, SCREEN_WIDTH, SCREEN_HEIGHT - statusHeight - 174)];
    [self.view addSubview:contentView];
    
    UILabel *contentTitle = [[UILabel alloc]initWithFrame:CGRectMake(15, 20, SCREEN_WIDTH - 20, 30)];
    contentTitle.textColor = UICOLOR_RGBA(141, 110, 99, 1);
    contentTitle.text = INTER_STR(@"EspBlufi-version");
    [contentView addSubview:contentTitle];
    
    NSArray *titleArr = @[INTER_STR(@"EspBlufi-app-version"), INTER_STR(@"EspBlufi-sdk-version"), INTER_STR(@"EspBlufi-update")];
    NSArray *contentArr = @[self.appversion, BLUFI_VERSION, self.updateStr];
    
    for (int i = 0; i < titleArr.count - 1; i ++) {
        UILabel *version = [[UILabel alloc]initWithFrame:CGRectMake(15, 70 + (60 * i), SCREEN_WIDTH - 20, 20)];
        version.text = titleArr[i];
        [version addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deviceFilter)]];
        version.userInteractionEnabled = NO;
        [contentView addSubview:version];
        
        UILabel *versionContent = [[UILabel alloc]initWithFrame:CGRectMake(15, 95 + (60 * i), SCREEN_WIDTH - 20, 20)];
        versionContent.textColor = [UIColor lightGrayColor];
        versionContent.font = [UIFont systemFontOfSize:16.0];
//        [versionContent addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deviceFilter)]];
//        versionContent.userInteractionEnabled = YES;
        versionContent.text = contentArr[i];
        [contentView addSubview:versionContent];
    }
}

- (void)deviceFilter {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:INTER_STR(@"EspBlufi-filter-content") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:INTER_STR(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:INTER_STR(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *filterTextField = alertController.textFields.firstObject;
        self.filterContent.text = filterTextField.text;
        [ESPDataConversion saveBlufiScanFilter:filterTextField.text];
        NSLog(@"过滤条件: %@", filterTextField.text);
    }]];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = INTER_STR(@"EspBlufi-filter-content");
    }];
    [self presentViewController:alertController animated:YES completion:nil];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
