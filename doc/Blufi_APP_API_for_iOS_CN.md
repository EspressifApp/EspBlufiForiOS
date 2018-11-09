#EspBlufi for iOS API 接口说明
------
为了方便用户进行 Blufi 的二次开发，我司针对 EspBlufi for iOS 提供了一些 API 接口。本文档将对这些接口进行简要介绍。详细指令说明请参考 `ESP蓝牙配网设计文档`

## 蓝牙配网概述
Espressif 的蓝牙配网，该功能称为BLUFI。
	BLUFI配网功能主要定义了使用GATT Server来实现被手机等（GATT Client）传入WIFI的必连接信息，从而实现 WIFI 能够连上 AP 或配置使用 SOFTAP 的 profile。
	BLUFI配网主要使用两个特性，一个特性作为接收手机端的数据，另一个特性用于发送数据给手机端。BLUFI包含了一些必要的功能，如BLUFI层分片、BLUFI 层数据加密和校验、BLUFI 层数据确认等。
	BLUFI配网的过程中的对称加密、非对称加密以及校验算法，都可由使用者实现，BLUFI提供的示例程序将默认将使用DH算法来协商密钥，128-AES来加密数据，以及CRC16来对数据进行校验。


## Blufi 配网流程
BLUFI配网包含了配置 SOFTAP 和 STATION 两部分。下面以配置 STATION 为例，说明配置步骤。
	BLUFI配网种的 STATION 配置项目包含了广播、连接、服务发现、协商共享密钥、传输数据、回传连接状态等步骤。
	完整配网过程如下：

	1. ESP32开启 GATT Server 功能，并发送带有特定 ADV data 的广播。（此广播由使用者自定义，不在 BLUFI Profile 内）
	2. 手机APP搜到该特定广播，作为 GATT Client 去连接ESP32。（手机APP由使用者自定义）
	3. GATT连接建立成功后，手机向ESP32发送『协商过程』的数据包（见BLUFI传输格式）。
	4. ESP32收到『协商过程』的数据包后，会解析按照使用者自定义的协商过程来解析。
	5. 手机与ESP32进行密钥协商。
	6. 协商结束后，手机端向ESP32发送『设置安全模式』的控制包。
	7. ESP32收到『设置安全模式』的控制包，以后将使用协商出来的共享密钥以及配置的安全策略对通信数据进行加解密。
	8. 手机向ESP32发送『BLUFI传输格式』定义的SSID、PASSWORD等用于WIFI连接的必要信息。
	9. 手机向ESP32发送『Wifi连接请求』的控制包，ESP32收到之后，认为手机已将必要的信息传输完毕，准备去连接WIFI。
	10. ESP32连接WIFI后，将发送『WIFI连接状态报告』的控制包给手机，以报告连接状态。配网结束。

	注意：
	1. 安全模式可以在任何时候进行设置，ESP32收到安全模式的配置后，就会根据安全模式指定的模式进行安全相关的操作。
	2. 对称加解密时，加解密前的数据长度和加解密后的数据长度必须一致，且支持原地加解密。
	

## Blufi service 说明
- 连接成功后，搜索并获得 `BluetoothGattService`
    - UUID 为 0xFFFF
- 获得 Service 后，获得 `BluetoothGattCharacteristic`
    - App 向 Device 写数据的 `BluetoothGattCharacteristic UUID` 为 0xFF01 
    - Device 向 App 推送消息的 `BluetoothGattCharacteristic UUID` 为 0xFF02，使用 Notification 方式
  
## BLE 初始化相关API
- 蓝牙初始化, 这里我们使用 BabyBluetooth 库
	`[BabyBluetooth shareBabyBluetooth]
	`

- 设置蓝牙代理, 后续所有的蓝牙事件都在这个代理函数中回调
	`[self BleDelegate]
	`

- 扫描周围的蓝牙广播, SCANTIME 后自动停止, 单位为秒
	`baby.scanForPeripherals().begin().stop(SCANTIME);
	`

- 连接ESP32, 建立蓝牙连接
	`-(void)connect:(CBPeripheral *)peripheral
	`

- 断开蓝牙连接
	`-(void)Disconnect:(CBPeripheral *)Peripheral
	`

- 断开所有蓝牙连接
	`-(void)CancelAllConnect
	`

- 添加自动重连, 蓝牙意外断开后自动重连
	`-(void)AutoReconnect:(CBPeripheral *)peripheral
	`

- 取消自动重连
	`- (void)AutoReconnectCancel:(CBPeripheral *)peripheral;
	`

- APP发送蓝牙数据到 ESP32 设备端
	`-(void)writeStructDataWithCharacteristic:(CBCharacteristic *)Characteristic WithData:(NSData *)data
	`
	
## 蓝牙连接后, 协商秘钥

#### 下方的API是生成对应的指令包, 然后调用发送蓝牙数据API`writeStructDataWithCharacteristic`将指令发送给ESP32

- 生成协商数据
	`+(NSData *)GenerateNegotiateData:(RSAObject *)rsaobject;
	`

- 发送协商数据的长度
	`+(NSMutableData *)SetNegotiatelength:(uint16_t)length Sequence:(uint8_t)sequence;
	`

- 发送协商数据包
	`+(NSData *)SendNegotiateData:(NSData *)somedata Sequence:(uint8_t)sequence Frag:(BOOL)flag TotalLength:(uint16_t)totallength;
	`

- 通知ESP32，ESP32发送数据时的使用的安全模式，过程中可多次设置。
每次设置后影响后续安全模式。不设置的情况下，ESP32认为控制包和数据包均为无校验、无加密。
	`+(NSMutableData *)SetESP32ToPhoneSecurityWithSecurity:(BOOL)security CheckSum:(BOOL)checksum Sequence:(uint8_t)sequence;
	`

- 解析收到的蓝牙数据包
	`-(void)analyseData:(NSMutableData *)data
	`
	在该函数中会自动解密数据, 设备数据包是数据包还是控制包, 然后调用对应的 API 处理. 控制包处理 `-(void)GetControlPacketWithData:(NSData *)data`, 数据包处理 `-(void)GetDataPackectWithData:(NSData *)data`

- 发送ack包, 用来回复对方发的包
	`+(NSMutableData *)ReturnAckWithSequence:(uint8_t)sequence BackSequence:(uint8_t)backsequence;
	` 
## 设置 ESP32 的工作模式(STATION MODE AND SOFTAP MODE)

#### 下方的API是生成对应的指令包, 然后调用发送蓝牙数据API`writeStructDataWithCharacteristic`将指令发送给ESP32

- 设置 ESP32 的工作模式.
	`+(NSMutableData *)SetOpmode:(Opmode)opmode Sequence:(uint8_t)sequence;
	`	
	opmode：0x00: NULL；0x01: STA; 0x02: SoftAP; 0x03: SoftAP & STA. 如果设置有包含AP，请尽量优先设置AP模式的SSID/	PASSWORD/Max Conn Number等。
	
##### 如果 ESP32 的工作模式为 STA MODE:

- 设置STA MODE 的 PASSWORD
	`+(NSMutableData *)SetStationPassword:(NSString *)password  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
	`
	
- 设置STA MODE 的 SSID
	`+(NSMutableData *)SetStationSsid:(NSString *)ssid  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
	`
	STA 的 PASSWORD 和 SSID 设置完成后, ESP32 会自动发起 STA 连接

##### 如果 ESP32 的工作模式为 SOFTAP MODE:
	
- 设置 SOFTAP 的 SSID
	`+(NSMutableData *)SetSoftAPSsid:(NSString *)ssid  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
	`
	
- 设置 SOFTAP 的 PASSWORD
	`+(NSMutableData *)SetSoftAPPassword:(NSString *)password  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
	`
	
- 设置 SOFTAP 的认证模式
	`+(NSMutableData *)SetAuthenticationforSoftAP:(AuthenticationMode)mode  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
	`
	
- 设置 SOFTAP 的工作信道
	`+(NSMutableData *)SetChannelforSoftAP:(uint8_t)channel  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
	`
	
- 设置 SOFTAP 的最大连接数
	`+(NSMutableData *)SetMaxConnectforSoftAP:(uint8_t)max  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
	`
	
- 连接 AP
	`+(NSMutableData *)ConnectToAPWithSequence:(uint8_t)sequence;
	`
	
- 断开 AP 连接
	`+(NSMutableData *)DisconnectFromAPWithSequence:(uint8_t)sequence;
	`

## 其他辅助指令
#### 下方的API是生成对应的指令包, 然后调用发送蓝牙数据API`writeStructDataWithCharacteristic`将指令发送给ESP32
- 获取ESP32的WIFI模式和状态等信息, ESP32收到此控制包后，后续会通过Wifi Connection State Report数据包来回复手机端当前所处的opmode、连接状态、SSID等信息。
	`+(NSMutableData *)GetDeviceInforWithSequence:(uint8_t)Sequence;
	`

- ESP32收到该指令后主动断开蓝牙连接, 一些安卓手机和苹果手机断开蓝牙连接有延时, 为了解决这个问题, 可以由ESP32主动断开蓝牙连接
	`+(NSMutableData *)DisconnectBLEWithSequence:(uint8_t)Sequence;
	`

- 通知ESP32扫描周围的WIFI热点, ESP32收到此控制包后，后续会通过 Wifi List Report 数据包来回复手机端当前 ESP32 周围的 Wifi 热点。
	`+(NSMutableData *)GetWifiListWithSequence:(uint8_t)Sequence;
	`

- 发送自定义数据包, 这个指令用户使用Blufi的加密协议发送自定义的数据包
	`+(NSMutableData *)SendCustomData:(NSData *)custom_data  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
	`
- CRC校验
	`+(BOOL)VerifyCRCWithData:(NSData *)data`

- 计算CRC
	`+(NSData *)GetCRCWithData:(NSData *)data`
