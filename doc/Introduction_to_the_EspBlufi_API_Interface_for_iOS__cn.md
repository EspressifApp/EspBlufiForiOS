[[en]](Introduction_to_the_EspBlufi_API_Interface_for_iOS__en.md)

# EspBlufi for iOS API 接口说明

------

为了方便用户进行 Blufi 的二次开发，我司针对 EspBlufi for iOS 提供了一些 API 接口。本文档将对这些接口进行简要介绍。

## 使用 BlufiClient 与 Device 发起通信

- 实例化 BlufiClient
    
    ```objective-c
    BlufiClient client = [[BlufiClient alloc] init];

    // 设置 Blufi 代理，接收 Blufi 事件，可参考 ESPDetailViewController
    client.blufiDelegate = blufiDelegate;

    // 设置 BLE 系统回调
    client.centralManagerDelete = centralManagerDelete;
    client.peripheralDelegate = peripheralDelegate;
    ```

- 设置 Blufi 发送数据时每包数据的最大长度

    ```objective-c
    // 设置长度限制，若数据超出限制将进行分包发送
    client.postPackageLengthLimit = 128;
    ```

- 与 Device 建立连接

    ```objective-c
    // 若 client 与设备建立连接，client 将主动扫描 Blufi 的服务和特征
    // 用户在收到 BlufiDelegate 回调 blufi:gettPrepared:service:writeChar:notifyChar: 后才可以与设备发起通信
    NSString *identifier = peripheral.identifier.UUIDString;
    [client connect:identifier];
    ```

- 与 Device 协商数据加密
    
    ```objective-c
    [client negotiateSecurity];
    ```

    ```objective-c
    // 协商结果在 BlufiDelegate 回调方法内通知
    - (void)blufi:(BlufiClient *)client didNegotiateSecurity:(BlufiStatusCode)status {
        // status 为 0 表示加密成功，否则为失败
    }
    ```

- 请求获取 Device 版本

    ```objective-c
    [client requestDeviceVersion];
    ```
    
    ```objective-c
    // 设备版本在 BlufiDelegate 回调方法内通知
    - (void)blufi:(BlufiClient *)client didReceiveDeviceVersionResponse:(nullable BlufiVersionResponse *)response status:(BlufiStatusCode)status {
        // status 为 0 表示加密成功，否则为失败
    
        if (status == StatusSuccess) {
            NSString *version = response.getVersionString; // 获得版本号
        }
    }
    ```

- 请求获取 Device 当前扫描到的 Wi-Fi 信号
    
    ```objective-c
    [client requestDeviceScan];
    ```
    
    ```objective-c
    // 扫描结果在 BlufiDelegate 回调方法内通知
    - (void)blufi:(BlufiClient *)client didReceiveDeviceScanResponse:(nullable NSArray<BlufiScanResponse *> *)scanResults status:(BlufiStatusCode)status {
        // status 为 0 表示获取数据成功，否则为失败
        
        if (status == StatusSuccess) {
            for (BlufiScanResponse *response in scanResults) {
                NSString *ssid = response.ssid; // 获得 Wi-Fi SSID
                int8_t rssi = response.rssi; // 获得 Wi-Fi RSSI
            }
        }
    }
    ```

- 发送自定义数据

    ```objective-c
    NSData *data = [@"Custom Data" dataUsingEncoding:NSUTF8StringEncoding];
    [client postCustomData:data];
    ```
    
    ```objective-c
    // 自定义数据发送结果在 BlufiDelegate 回调方法内通知
    - (void)blufi:(BlufiClient *)client didPostCustomData:(NSData *)data status:(BlufiStatusCode)status {
        // status 为 0 表示发送成功，否则为发送失败
        // data 为需要发送的自定义数据
    }
    
    // 收到 Device 端发送的自定义数据
    - (void)blufi:(BlufiClient *)client didReceiveCustomData:(NSData *)data status:(BlufiStatusCode)status {
        // status 为 0 表示成功接收
        // data 为收到的数据
    }
    ```

- 请求获取 Device 当前状态

    ```objective-c
    [client requestDeviceStatus];
    ```
    
    ```objective-c
    // Device 状态在 BlufiDelegate 回调方法内通知
    - (void)blufi:(BlufiClient *)client didReceiveDeviceStatusResponse:(nullable BlufiStatusResponse *)response status:(BlufiStatusCode)status
        // status 为 0 表示获取状态成功，否则为失败
    
        if (status == StatusSuccess) {
            OpMode opMode = response.opMode;
            if (opMode == OpModeSta) {
                // 当前为 Station 模式
                int conn = response.staConnectionStatus; // 获取 Device 当前连接状态：0 表示有 Wi-Fi 连接，否则没有 Wi-Fi 连接
                NSString *ssid = response.staSsid; // 获取 Device 当前连接的 Wi-Fi 的 SSID
                NSString *bssid = response.staBssid; // 获取 Device 当前连接的 Wi-Fi 的 BSSID
                NSString *password = response.staPassword; // 获取 Device 当前连接的 Wi-Fi 密码
            } else if (opMode == OpModeSoftAP) {
                // 当前为 SoftAP 模式
                NSString *ssid = response.softApSsid; // 获取 Device 的 SSID
                int channel = response.softApChannel; // 获取 Device 的信道
                SoftAPSecurity security = response.softApSecurity; // 获取 Device 的加密方式：0 为不加密，2 为 WPA，3 为 WPA2，4 为 WPA/WPA2， 参考 enum SoftAPSecurity
                int maxConn = response.softApMaxConnection; // 最多可连接的 Device 个数
                int currentConn = response.softApConnectionCount; // 当前已连接 的 Device 个数
            } else if (opMode == OpModeStaSoftAP) {
                // 当前为 Station 和 SoftAP 共存模式
                // 获取状态方法同 Station 模式和 SoftAP 模式
            }
        }
    }
    ```

- 对 Device 进行配网
    
    ```objective-c
    BlufiConfigureParams *params = [[BlufiConfigureParams alloc] init];
    OpMode opMode = OpModeNull; // 设置需要配置的模式：1 为 Station 模式，2 为 SoftAP 模式，3 为 Station 和 SoftAP 共存模式, 参考 enum OpMode
    if (opMode == OpModeSta) {
        params.staSsid = @"sta ssid"; // 设置 Wi-Fi SSID
        params.staPassword = @"sta password"; // 设置 Wi-Fi 密码，若是开放 Wi-Fi 则不设或设空
        // 注意：Device 不支持连接 5G Wi-Fi，建议提前检查一下是不是 5G Wi-Fi
    } else if (opMode == OpModeSoftAP) {
        params.softApSsid = @"softap ssid"; // 设置 Device 的 SSID
        params.softApSecurity = SoftAPSecurityWPA; // 设置 Device 的加密方式：0 为不加密，2 为 WPA，3 为 WPA2，4 为 WPA/WPA2， 参考 enum SoftAPSecurity
        params.softApPassword = @"softap password"; // 若 Security 非 0 则必须设置 
        params.softApChannel = channel; // 设置 Device 的信道, 可不设
        params.softApMaxConnection = 4; // 设置可连接 Device 的最大个数
    } else if (opMode == OpModeStaSoftAP) {
        // 同上两个
    }
    [client configure:params];
    ```
    
    ```objective-c
    // 设置信息发送结果在 BlufiDelegate 回调方法内通知
    - (void)blufi:(BlufiClient *)client didPostConfigureParams:(BlufiStatusCode)status {
        // Status 为 0 表示发送配置信息成功，否则为失败
    }
    
    // 配置后的状态变化回调
    - (void)blufi:(BlufiClient *)client didReceiveDeviceStatusResponse:(nullable BlufiStatusResponse *)response status:(BlufiStatusCode)status {
        // 同上方请求获取设备当前状态
    }
    ```

- 请求 Device 断开 BLE 连接
    
    ```objective-c
    // 有时 Device 端无法获知 app 端已主动断开连接, 此时会导致 app 后续无法重新连上设备
    [client requestCloseConnection];
    ```

- 关闭 BlufiClient Close BlufiClient
    
    ```objective-c
    // 释放资源
    [client close];
    ```

## BlufiDelegate 说明

```objective-c
// 当扫描 Gatt 服务结束后调用该方法
// service, writeChar, notifyChar 中有 nil 的时候表示扫描失败
- (void)blufi:(BlufiClient *)client gattPrepared:(BlufiStatusCode)status service:(nullable CBService *)service writeChar:(nullable CBCharacteristic *)writeChar notifyChar:(nullable CBCharacteristic *)notifyChar;

// 收到 Device 的通知数据
// 返回 NO 表示处理尚未结束，交给 BlufiClient 继续后续处理
// 返回 YES 表示处理结束，后续将不再解析该数据，也不会调用回调方法
- (BOOL)blufi:(BlufiClient *)client gattNotification:(NSData *)data packageType:(PackageType)pkgType subType:(SubType)subType;

// 收到 Device 发出的错误代码
- (void)blufi:(BlufiClient *)client didReceiveError:(NSInteger)errCode;

// 与 Device 协商加密的结果
- (void)blufi:(BlufiClient *)client didNegotiateSecurity:(BlufiStatusCode)status;

// 发送配置信息的结果
- (void)blufi:(BlufiClient *)client didPostConfigureParams:(BlufiStatusCode)status;

// 收到 Device 的版本信息
- (void)blufi:(BlufiClient *)client didReceiveDeviceVersionResponse:(nullable BlufiVersionResponse *)response status:(BlufiStatusCode)status;

// 收到 Device 的状态信息
- (void)blufi:(BlufiClient *)client didReceiveDeviceStatusResponse:(nullable BlufiStatusResponse *)response status:(BlufiStatusCode)status;

// 收到 Device 扫描到的 Wi-Fi 信息
- (void)blufi:(BlufiClient *)client didReceiveDeviceScanResponse:(nullable NSArray<BlufiScanResponse *> *)scanResults status:(BlufiStatusCode)status;

// 发送自定义数据的结果
- (void)blufi:(BlufiClient *)client didPostCustomData:(NSData *)data status:(BlufiStatusCode)status;

// 收到 Device 的自定义信息
- (void)blufi:(BlufiClient *)client didReceiveCustomData:(NSData *)data status:(BlufiStatusCode)status;
```