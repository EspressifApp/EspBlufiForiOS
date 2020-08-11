//
//  ESPDetailViewController.m
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/10.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "ESPDetailViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "ESPProvisionViewController.h"
#import "BlufiClient.h"

typedef enum {
    TagConnect = 6000,
    TagDisconnect,
    TagSecurity,
    TagVersion,
    TagConfigure,
    TagState,
    TagScan,
    TagCustom,
} TagButton;

@interface ESPDetailViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, BlufiDelegate, UITableViewDelegate, UITableViewDataSource, ConfigureParamsDelegate>

@property(strong, nonatomic)UIButton *connectBtn;
@property(strong, nonatomic)UIButton *disConnectBtn;
@property(strong, nonatomic)UIButton *encryptionBtn;
@property(strong, nonatomic)UIButton *versionBtn;
@property(strong, nonatomic)UIButton *configureBtn;
@property(strong, nonatomic)UIButton *stateBtn;
@property(strong, nonatomic)UIButton *scanBtn;
@property(strong, nonatomic)UIButton *customBtn;

@property(strong, nonatomic)UITableView *messageView;
@property(strong, nonatomic)NSMutableArray *messageArray;

@property(strong, nonatomic)BlufiClient *blufiClient;
@property(assign, atomic)BOOL connected;

@end

@implementation ESPDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = _device.name;
    self.connected = NO;
    [self setupBasedView];
}

- (void)setupBasedView {
    UIView *reminderView = [[UIView alloc] initWithFrame:CGRectMake(0, statusHeight + 44, SCREEN_WIDTH, SCREEN_HEIGHT - statusHeight - 164)];
//    reminderView.backgroundColor = UICOLOR_RGBA(221, 221, 221, 1);
    [self.view addSubview:reminderView];
    
    UIView *operationView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 120, SCREEN_HEIGHT, 100)];
    [self.view addSubview:operationView];
    
    NSArray *operationArr = @[INTER_STR(@"EspBlufi-operation-connect"), INTER_STR(@"EspBlufi-operation-disConnect"), INTER_STR(@"EspBlufi-operation-encryption"), INTER_STR(@"EspBlufi-operation-version"), INTER_STR(@"EspBlufi-operation-provision"), INTER_STR(@"EspBlufi-operation-state"), INTER_STR(@"EspBlufi-operation-scan"), INTER_STR(@"EspBlufi-operation-custom")];
    for (int i = 0; i < operationArr.count; i ++ ) {
        int firstCount = 0;
        int twoCount = 0;
        if (i < 4) {
            firstCount = ((SCREEN_WIDTH - 40) / 4 + 10) * i;
        } else {
            firstCount = ((SCREEN_WIDTH - 40) / 4 + 10) * (i - 4);
            twoCount = 50;
        }
        UIButton *myButton = [[UIButton alloc] initWithFrame:CGRectMake(5 + firstCount, 5 + twoCount, (SCREEN_WIDTH - 40) / 4, 40)];
        [myButton setTitle:operationArr[i] forState:0];
        [myButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        myButton.tag = TagConnect + i;
        [myButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [myButton addTarget:self action:@selector(onButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [myButton addTarget:self action:@selector(onButtonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
        myButton.layer.cornerRadius = 5.0;
        myButton.clipsToBounds = YES;
        if (i == 0) {
            [self setButton:myButton enable:YES];
        } else {
            [self setButton:myButton enable:NO];
        }
        switch (myButton.tag) {
            case TagConnect:
                self.connectBtn = myButton;
                break;
            case TagDisconnect:
                self.disConnectBtn = myButton;
                break;
            case TagSecurity:
                self.encryptionBtn = myButton;
                break;
            case TagVersion:
                self.versionBtn = myButton;
                break;
            case TagConfigure:
                self.configureBtn = myButton;
                break;
            case TagState:
                self.stateBtn = myButton;
                break;
            case TagScan:
                self.scanBtn = myButton;
                break;
            case TagCustom:
                self.customBtn = myButton;
                break;
            default:
                break;
        }
        [operationView addSubview:myButton];
    }
    
    _messageView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 130)];
    _messageView.backgroundColor = [UIColor colorWithRed:80 green:80 blue:80 alpha:1];
    _messageArray = [[NSMutableArray alloc] init];
    _messageView.delegate = self;
    _messageView.dataSource = self;
    [self.view addSubview:_messageView];
}

- (void)setButton:(UIButton *)button enable:(BOOL)enable {
    if (enable) {
        button.userInteractionEnabled = YES;
        button.backgroundColor = navColor;
        [button setTitleColor:[UIColor whiteColor] forState:0];
    } else {
        button.userInteractionEnabled = NO;
        button.backgroundColor = UICOLOR_RGBA(221, 221, 221, 1);
        [button setTitleColor:[UIColor lightGrayColor] forState:0];
    }
}

- (void)setButton:(UIButton *)button pressed:(BOOL)pressed {
    if (!button.userInteractionEnabled) {
        button.backgroundColor = UICOLOR_RGBA(221, 221, 221, 1);
        [button setTitleColor:[UIColor lightGrayColor] forState:0];
    } else {
        if (pressed) {
            button.backgroundColor = UICOLOR_RGBA(200, 40, 80, 1);
            [button setTitleColor:[UIColor whiteColor] forState:0];
        } else {
            button.backgroundColor = navColor;
            [button setTitleColor:[UIColor whiteColor] forState:0];
        }
    }
}

- (void)onButtonTouchDown:(UIButton *)sender {
    [self setButton:sender pressed:YES];
}

- (void)onButtonTouchUp:(UIButton *)sender {
    [self setButton:sender pressed:NO];
}

- (void)onButtonPressed:(UIButton *)sender {
    sender.selected = !sender.selected;
    switch (sender.tag) {
        case TagConnect:
            [self connect];
            break;
        case TagDisconnect:
            if (_blufiClient) {
                [_blufiClient requestCloseConnection];
            }
            break;
        case TagSecurity:
            [self setButton:sender enable:NO];
            if (_blufiClient) {
                [_blufiClient negotiateSecurity];
            }
            break;
        case TagVersion:
            [self setButton:sender enable:NO];
            if (_blufiClient) {
                [_blufiClient requestDeviceVersion];
            }
            break;
        case TagConfigure:
            [self pushProvision];
            break;
        case TagState:
            [self setButton:sender enable:NO];
            if (_blufiClient) {
                [_blufiClient requestDeviceStatus];
            }
            break;
        case TagScan:
            [self setButton:sender enable:NO];
            if (_blufiClient) {
                [_blufiClient requestDeviceScan];
            }
            break;
        case TagCustom:
            [self setButton:self.customBtn enable:NO];
            [self showCustomDataAlert];
            break;
        default:
            break;
    }
    [self setButton:sender pressed:NO];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _messageArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    if (!ValidArray(_messageArray)) {
        return cell;
    }
    
    NSString *message = _messageArray[indexPath.row];
    cell.textLabel.text = message;
    cell.textLabel.numberOfLines = 0;
    return cell;
}

- (void)updateMessage:(NSString *)message {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.messageArray addObject:message];
        NSArray *insertIndexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.messageArray.count-1 inSection:0]];
        [self.messageView beginUpdates];
        [self.messageView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.messageView endUpdates];
        [self.messageView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self->_messageArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }];
}

- (void)connect {
    [self setButton:_connectBtn enable:NO];
    if (_blufiClient) {
        [_blufiClient close];
        _blufiClient = nil;
    }
    
    _blufiClient = [[BlufiClient alloc] init];
    _blufiClient.centralManagerDelete = self;
    _blufiClient.peripheralDelegate = self;
    _blufiClient.blufiDelegate = self;
    [_blufiClient connect:_device.uuid.UUIDString];
}

- (void)pushProvision {
    ESPProvisionViewController *pvc = [ESPProvisionViewController new];
    pvc.paramsDelegate = self;
    [self.navigationController pushViewController:pvc animated:YES];
}

- (void)didSetParams:(BlufiConfigureParams *)params {
    if (_blufiClient && _connected) {
        [_blufiClient configure:params];
    }
}

- (void)showCustomDataAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:INTER_STR(@"EspBlufi-custom-data") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:INTER_STR(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self setButton:self.customBtn enable:self.connected];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:INTER_STR(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setButton:self.customBtn enable:self.connected];
        UITextField *filterTextField = alertController.textFields.firstObject;
        NSString *text = filterTextField.text;
        if (text && text.length > 0 && self.blufiClient) {
            NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
            [self.blufiClient postCustomData:data];
        }
    }]];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = INTER_STR(@"EspBlufi-custom-data-hint");
    }];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)onDisconnected {
    if (_blufiClient) {
        [_blufiClient close];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setButton:self.connectBtn enable:YES];
        
        [self setButton:self.disConnectBtn enable:NO];
        [self setButton:self.encryptionBtn enable:NO];
        [self setButton:self.versionBtn enable:NO];
        [self setButton:self.configureBtn enable:NO];
        [self setButton:self.stateBtn enable:NO];
        [self setButton:self.scanBtn enable:NO];
        [self setButton:self.customBtn enable:NO];
    }];
}

- (void)onBlufiPrepared {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setButton:self.connectBtn enable:NO];
        
        [self setButton:self.disConnectBtn enable:YES];
        [self setButton:self.encryptionBtn enable:YES];
        [self setButton:self.versionBtn enable:YES];
        [self setButton:self.configureBtn enable:YES];
        [self setButton:self.stateBtn enable:YES];
        [self setButton:self.scanBtn enable:YES];
        [self setButton:self.customBtn enable:YES];
    }];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self updateMessage:@"Connected device"];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self updateMessage:@"Connet device failed"];
    self.connected = NO;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self onDisconnected];
    [self updateMessage:@"Disconnected device"];
    self.connected = NO;
}

- (void)blufi:(BlufiClient *)client gattPrepared:(BlufiStatusCode)status service:(CBService *)service writeChar:(CBCharacteristic *)writeChar notifyChar:(CBCharacteristic *)notifyChar {
    NSLog(@"Blufi gattPrepared status:%d", status);
    if (status == StatusSuccess) {
        self.connected = YES;
        [self updateMessage:@"BluFi connection has prepared"];
        [self onBlufiPrepared];
    } else {
        [self onDisconnected];
        if (!service) {
            [self updateMessage:@"Discover service failed"];
        } else if (!writeChar) {
            [self updateMessage:@"Discover write char failed"];
        } else if (!notifyChar) {
            [self updateMessage:@"Discover notify char failed"];
        }
    }
}

- (void)blufi:(BlufiClient *)client didNegotiateSecurity:(BlufiStatusCode)status {
    NSLog(@"Blufi didNegotiateSecurity %d", status);
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setButton:self.encryptionBtn enable:self.connected];
    }];
    if (status == StatusSuccess) {
        [self updateMessage:@"Negotiate security complete"];
    } else {
        [self updateMessage:[NSString stringWithFormat:@"Negotiate security failed: %d", status]];
    }
}

- (void)blufi:(BlufiClient *)client didReceiveDeviceVersionResponse:(BlufiVersionResponse *)response status:(BlufiStatusCode)status {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setButton:self.versionBtn enable:self.connected];
    }];
    if (status == StatusSuccess) {
        [self updateMessage:[NSString stringWithFormat:@"Receive device version: %@", response.getVersionString]];
    } else {
        [self updateMessage:[NSString stringWithFormat:@"Receive device version error: %d", status]];
    }
}

- (void)blufi:(BlufiClient *)client didPostConfigureParams:(BlufiStatusCode)status {
    if (status == StatusSuccess) {
        [self updateMessage:@"Post configure params complete"];
    } else {
        [self updateMessage:[NSString stringWithFormat:@"Post configure params failed: %d", status]];
    }
}

- (void)blufi:(BlufiClient *)client didReceiveDeviceStatusResponse:(BlufiStatusResponse *)response status:(BlufiStatusCode)status {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setButton:self.stateBtn enable:self.connected];
    }];
    if (status == StatusSuccess) {
        [self updateMessage:[NSString stringWithFormat:@"Receive device status:\n%@", response.getStatusInfo]];
    } else {
        [self updateMessage:[NSString stringWithFormat:@"Receive device status error: %d", status]];
    }
}

- (void)blufi:(BlufiClient *)client didReceiveDeviceScanResponse:(NSArray<BlufiScanResponse *> *)scanResults status:(BlufiStatusCode)status {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setButton:self.scanBtn enable:self.connected];
    }];
    if (status == StatusSuccess) {
        NSMutableString *info = [[NSMutableString alloc] init];
        [info appendString:@"Receive device scan results:\n"];
        for (BlufiScanResponse *response in scanResults) {
            [info appendFormat:@"SSID: %@, RSSI: %d\n", response.ssid, response.rssi];
        }
        [self updateMessage:info];
    } else {
        [self updateMessage:[NSString stringWithFormat:@"Receive device scan results error: %d", status]];
    }
}

- (void)blufi:(BlufiClient *)client didPostCustomData:(nonnull NSData *)data status:(BlufiStatusCode)status {
    if (status == StatusSuccess) {
        [self updateMessage:@"Post custom data complete"];
    } else {
        [self updateMessage:[NSString stringWithFormat:@"Post custom data failed: %d", status]];
    }
}

- (void)blufi:(BlufiClient *)client didReceiveCustomData:(NSData *)data status:(BlufiStatusCode)status {
    NSString *customString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self updateMessage:[NSString stringWithFormat:@"Receive device custom data: %@", customString]];
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
