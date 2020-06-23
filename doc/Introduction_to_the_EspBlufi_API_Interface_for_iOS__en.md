[[cn]](Introduction_to_the_EspBlufi_API_Interface_for_iOS__cn.md)

# Introduction to the EspBlufi API Interface for iOS
------
This guide is a basic introduction to the APIs provided by Espressif to facilitate the customers' secondary development of BluFi.

## Communicate with the device using BlufiClient

- Create a BlufiClient instance

    ```objective-c
    BlufiClient client = [[BlufiClient alloc] init];

    // Set Blufi delegate to receive Blufi events. Please refer to ESPDetailViewController.
    client.blufiDelegate = blufiDelegate;
    
    // Set BLE system callback
	client.centralManagerDelete = centralManagerDelete;
    client.peripheralDelegate = peripheralDelegate;
    ```

- Configure the maximum length of each data packet

    ```objective-c
    // Configure the maximum length of each post packet. If the length of a post packet exceeds the maximum packet length, the post packet will be split into fragments.
    client.postPackageLengthLimit = 128;
    ```

- Establish a BLE connection

	```objective-c
	// If establish connection successfully，client will discover service and characteristic for Blufi
	// client can communicate with Device after receive callback function 'blufi:gettPrepared:service:writeChar:notifyChar:' in BlufiDelegate
	NSString *identifier = peripheral.identifier.UUIDString;
    [client connect:identifier];
	```

- Negotiate data security with the device

    ```objective-c
    [client negotiateSecurity];
    ```

    ```objective-c
    // The result of negotiation will be sent back by the BlufiDelegate function
    - (void)blufi:(BlufiClient *)client didNegotiateSecurity:(BlufiStatusCode)status {
        // status is the result of negotiation: "0" - successful, otherwise - failed.
    }
    ```

- Request Device Version

    ```objective-c
    [client requestDeviceVersion];
    ```
    ```objective-c
    // The device version is notified in the BlufiDelegate function
    - (void)blufi:(BlufiClient *)client didReceiveDeviceVersionResponse:(nullable BlufiVersionResponse *)response status:(BlufiStatusCode)status {
        // status is the result: "0" - successful, otherwise - failed.
    
        if (status == StatusSuccess) {
            NSString *version = response.getVersionString; // Get the version number
        }
    }
    ```

- Request the device's current Wi-Fi scan result

    ```objective-c
    [client requestDeviceScan];
    ```

    ```objective-c
    // The scan result is notified in the BlufiDelegate function
    - (void)blufi:(BlufiClient *)client didReceiveDeviceScanResponse:(nullable NSArray<BlufiScanResponse *> *)scanResults status:(BlufiStatusCode)status {
        // status is the result: "0" - successful, otherwise - failed.
        
        if (status == StatusSuccess) {
            for (BlufiScanResponse *response in scanResults) {
                NSString *ssid = response.ssid; // Obtain Wi-Fi SSID
                int8_t rssi = response.rssi; // Obtain Wi-Fi RSSI
            }
        }
    }
    ```

- Send custom data

    ```objective-c
    NSData *data = [@"Custom Data" dataUsingEncoding:NSUTF8StringEncoding];
    [client postCustomData:data];
    ```
        
    ```objective-c
    // The result of sending custom data is notified in the BlufiDelegate function
    - (void)blufi:(BlufiClient *)client didPostCustomData:(NSData *)data status:(BlufiStatusCode)status {
        // status is the result: "0" - successful, otherwise - failed.
        // data is the custom data to be sent
    }

    // Receive custom data sent by the device
    - (void)blufi:(BlufiClient *)client didReceiveCustomData:(NSData *)data status:(BlufiStatusCode)status {
        // status is the result: "0" - successful, otherwise - failed.
        // data is the custom data received
    }
    ```

- Request the current status of the device

    ```objective-c
    [client requestDeviceStatus];
    ```

    ```objective-c
    // The device status is notified in the BlufiDelegate function.
    - (void)blufi:(BlufiClient *)client didReceiveDeviceStatusResponse:(nullable BlufiStatusResponse *)response status:(BlufiStatusCode)status
        // status is the result: "0" - successful, otherwise - failed.
    
        if (status == StatusSuccess) {
            OpMode opMode = response.opMode;
            if (opMode == OpModeSta) {
                // Station mode is currently enabled.
                int conn = response.staConnectionStatus; // Obtain the current status of the device: "0" - Wi-Fi connection established, otherwise - no Wi-Fi connection.
                NSString *ssid = response.staSsid; // Obtain the SSID of the current Wi-Fi connection
                NSString *bssid = response.staBssid; // Obtain the BSSID of the current Wi-Fi connection
                NSString *password = response.staPassword; // Obtain the password of the current Wi-Fi connection
            } else if (opMode == OpModeSoftAP) {
                // SoftAP mode is currently enabled
                NSString *ssid = response.softApSsid; // Obtain the device SSID
                int channel = response.softApChannel; // Obtain the device channel
                int security = response.softApSecurity; // Obtain the security option of the device: "0" - no security, "2" - WPA, "3" - WPA2, "4" - WPA/WPA2. See enum SoftAPSecurity
                int maxConn = response.softApMaxConnection; // The number of maximum connections
                int currentConn = response.softApConnectionCount; // The number of existing connections
            } else if (opMode == OpModeStaSoftAP) {
                // Station/SoftAP mode is currently enabled
                // Similar to Station and SoftAP modes
            }
        }
    }
    ```

- Configure the device

    ```objective-c
    BlufiConfigureParams *params = [[BlufiConfigureParams alloc] init];
    OpMode opMode = OpModeNull; // // Configure the device mode: "1" - Station, "2" - SoftAP, "3" - Station/SoftAP. See enum OpMode.
    if (opMode == OpModeSta) {
        params.staSsid = @"sta ssid"; // Configure the Wi-Fi SSID
        params.staPassword = @"sta password"; // Configure the Wi-Fi password. For public Wi-Fi networks, this option can be ignored or configured to return void.
        // Note: 5G Wi-Fi is not supported by the device. Please have a look.
    } else if (opMode == OpModeSoftAP) {
        params.softApSsid = @"softap ssid"; // Configure the device SSID
        params.softApSecurity = SoftAPSecurityWPA; // Configure the security option of the device: "0" - no security, "2" - WPA, "3" - WPA2, "4" - WPA/WPA2.. See enum SoftAPSecurity.
        params.softApPassword = @"softap password"; // This option is mandatory, if the security option value is not "0".
        params.softApChannel = channel; // Configure the device channel
        params.softApMaxConnection = 4; // Configure the number of maximum connections for the device
    } else if (opMode == OpModeStaSoftAP) {
        // Similar to Station and SoftAP modes
    }
    [client configure:params];
    ```

    ```objective-c
    // The result of data sending obtained with the BlufiDelegate function
    - (void)blufi:(BlufiClient *)client didPostConfigureParams:(BlufiStatusCode)status {
        // status is the result: "0" - successful, otherwise - failed.
    }

    // Indicate the change of status after the configuration
    - (void)blufi:(BlufiClient *)client didReceiveDeviceStatusResponse:(nullable BlufiStatusResponse *)response status:(BlufiStatusCode)status {
        // Request the current status of the device
    }
    ```

- Request the device to break BLE connection
    ```objective-c
    // If the app breaks a connection with the device and the device has not detected this fact, the app has no means to re-establish the connection.
    [client requestCloseConnection];
    ```

- Close BlufiClient
    ```objective-c
    // Release resources
    [client close];
    ```

## Notes on BlufiDelegate

```objective-c
// Discover Gatt service over
// Discover failed if service, writeChar or notifyChar is nil
- (void)blufi:(BlufiClient *)client gattPrepared:(BlufiStatusCode)status service:(nullable CBService *)service writeChar:(nullable CBCharacteristic *)writeChar notifyChar:(nullable CBCharacteristic *)notifyChar;

// Receive the notification of the device
// NO indicates that the processing has not been completed yet and that the procewssing will be transferred to BlufiClient.
// YES indicates that the processing has been completed and there will be no data processing or function calling afterwards.
- (BOOL)blufi:(BlufiClient *)client gattNotification:(NSData *)data packageType:(PackageType)pkgType subType:(SubType)subType;

// Error code sent by the device
- (void)blufi:(BlufiClient *)client didReceiveError:(NSInteger)errCode;

// The result of the security negotiation with the device
- (void)blufi:(BlufiClient *)client didNegotiateSecurity:(BlufiStatusCode)status;

// The result of the device configuration
- (void)blufi:(BlufiClient *)client didPostConfigureParams:(BlufiStatusCode)status;

// Information on the received device version
- (void)blufi:(BlufiClient *)client didReceiveDeviceVersionResponse:(nullable BlufiVersionResponse *)response status:(BlufiStatusCode)status;

// Information on the received device status
- (void)blufi:(BlufiClient *)client didReceiveDeviceStatusResponse:(nullable BlufiStatusResponse *)response status:(BlufiStatusCode)status;

// Information on the received device Wi-Fi scan
- (void)blufi:(BlufiClient *)client didReceiveDeviceScanResponse:(nullable NSArray<BlufiScanResponse *> *)scanResults status:(BlufiStatusCode)status;

// The result of sending custom data
- (void)blufi:(BlufiClient *)client didPostCustomData:(NSData *)data status:(BlufiStatusCode)status;

// The received custom data from the device
- (void)blufi:(BlufiClient *)client didReceiveCustomData:(NSData *)data status:(BlufiStatusCode)status;
```