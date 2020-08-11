//
//  BlufiClient.m
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "BlufiClient.h"
#import "BlufiNotifyData.h"
#import "BlufiFrameCtrlData.h"
#import "BlufiSecurity.h"
#import "BlufiConfigureParams.h"

#define PACKAGE_LENGTH_DEFAULT   128
#define PACKAGE_LENGTH_MIN       20
#define PACKAGE_HEADER_LENGTH    4

#define DBUG false

typedef enum {
    StateConnected = 0,
    StateDisconnected,
} ConnectionState;

typedef enum {
    NotifyComplete = 0,
    NotifyHasFrag,
    NotifyNull,
    NotifyInvalidLength,
    NotifyInvalidSequence,
    NotifyInvalidChecsum,
    NotifyError,
} NotifyStatus;

enum {
    NegSecuritySetTotalLength = 0,
    NegSecuritySetAllData,
};

@interface EspBlockingQueue : NSObject

- (void)enqueue:(id)object;

- (id)dequeue;

- (void)cancel;

@end

@interface BlufiClient() <CBCentralManagerDelegate, CBPeripheralDelegate>

@property(strong, nonatomic, readonly)CBPeripheral *peripheral;

@property(strong, nonatomic)NSOperationQueue *requestQueue;
@property(strong, nonatomic)NSOperationQueue *callbackQueue;

@property(strong, nonatomic)NSUUID *identifier;

@property(strong, nonatomic)CBCentralManager *centralManager;
@property(strong, nonatomic)CBService *service;
@property(strong, nonatomic)CBUUID const *writeUUID;
@property(strong, nonatomic)CBCharacteristic *writeChar;
@property(strong, nonatomic)NSCondition *writeCondition;
@property(strong, nonatomic)CBUUID const *notifyUUID;
@property(strong, nonatomic)CBCharacteristic *notifyChar;

@property(assign, atomic)BOOL blePowerOn;
@property(assign, atomic)BOOL bleConnectMark;

@property(assign, atomic)NSInteger sendSequence;
@property(assign, atomic)NSInteger readSequence;

@property(strong, nonatomic)BlufiNotifyData *notifyData;

@property(strong, nonatomic)NSData *aesKey;

@property(assign, nonatomic)BOOL encrypted;
@property(assign, nonatomic)BOOL checksum;
@property(assign, nonatomic)BOOL requireAck;

@property(strong, nonatomic)EspBlockingQueue *deviceAck;
@property(strong, nonatomic)EspBlockingQueue *deviceKey;

@property(assign, nonatomic)ConnectionState connectState;

@property(assign, nonatomic)BOOL closed;

@end

@implementation BlufiClient

- (instancetype)init {
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _writeUUID = [CBUUID UUIDWithString:UUID_WRITE_CHAR];
        _writeCondition = [[NSCondition alloc] init];
        _notifyUUID = [CBUUID UUIDWithString:UUID_NOTIFY_CHAR];
        _callbackQueue = [NSOperationQueue mainQueue];
        _requestQueue = [[NSOperationQueue alloc] init];
        _requestQueue.maxConcurrentOperationCount = 1;
        
        _bleConnectMark = NO;
        _blePowerOn = NO;
        
        _postPackageLengthLimit = PACKAGE_LENGTH_DEFAULT;
        
        _sendSequence = -1;
        _readSequence = -1;
        
        _encrypted = NO;
        _checksum = NO;
        _requireAck = NO;
        
        _deviceAck = [[EspBlockingQueue alloc] init];
        _deviceKey = [[EspBlockingQueue alloc] init];
        
        _closed = NO;
    }
    return self;
}

- (NSString *)hexFromUint4:(Byte)b {
    switch (b) {
        case 0: return @"0";
        case 1: return @"1";
        case 2: return @"2";
        case 3: return @"3";
        case 4: return @"4";
        case 5: return @"5";
        case 6: return @"6";
        case 7: return @"7";
        case 8: return @"8";
        case 9: return @"9";
        case 10: return @"A";
        case 11: return @"B";
        case 12: return @"C";
        case 13: return @"D";
        case 14: return @"E";
        case 15: return @"F";
    }
    return nil;
}

- (NSString *)hexFromBytes:(Byte *)bytes length:(NSInteger)length{
    NSMutableString *hex = [[NSMutableString alloc] init];
    for (NSInteger i = 0; i < length; ++i) {
        Byte b = bytes[i];
        [hex appendString:[self hexFromUint4:(b >> 4 & 0xf)]];
        [hex appendString:[self hexFromUint4:(b & 0xf)]];
    }
    return hex;
}

- (void)setPostPackageLengthLimit:(NSInteger)postPackageLengthLimit {
    if (postPackageLengthLimit <= PACKAGE_LENGTH_MIN) {
        _postPackageLengthLimit = PACKAGE_LENGTH_MIN;
    } else {
        _postPackageLengthLimit = postPackageLengthLimit;
    }
}

- (void)close {
    _closed = YES;
    [_callbackQueue cancelAllOperations];
    [_requestQueue cancelAllOperations];
    [_centralManager stopScan];
    [self clearConnection];
    
    _blufiDelegate = nil;
    _centralManagerDelete = nil;
    _peripheralDelegate = nil;
    _centralManager.delegate = nil;
    
    [_deviceAck cancel];
    [_deviceKey cancel];
}

- (void)scanBLE {
    NSLog(@"Blufi Scan device: %@", _identifier);
    [_centralManager scanForPeripheralsWithServices:nil options:nil];
}

- (void)connect:(NSString *)identifier {
    if (_closed) {
        @throw [[NSException alloc] initWithName:@"NSStateException" reason:@"The BlufiClient is closed" userInfo:nil];
        return;
    }
    [self clearConnection];
    _identifier = [[NSUUID alloc] initWithUUIDString:identifier];
    if (_blePowerOn) {
        [self scanBLE];
    } else {
        _bleConnectMark = YES;
    }
}

- (void)clearConnection {
    _bleConnectMark = NO;
    _connectState = StateDisconnected;
    if (_peripheral) {
        [_centralManager cancelPeripheralConnection:_peripheral];
        _peripheral = nil;
    }
    _service = nil;
    _writeChar = nil;
    _notifyChar = nil;
    [_deviceAck cancel];
}

- (Byte)getTypeValueWithPackageType:(PackageType)pkgType subType:(SubType)subType {
    return (subType << 2) | pkgType;
}

- (PackageType)getPackageTypeWithTypeValue:(NSInteger)typeValue {
    return typeValue & 0b11;
}

- (SubType)getSubTypeWithTypeValue:(NSInteger)typeValue {
    return ((typeValue & 0b11111100) >> 2);
}

- (Byte)generateSendSequence {
    return (++_sendSequence) & 0xff;
}

- (NSData *)generateAESIV:(Byte)sequence {
    Byte buf[16];
    memset(buf, 0, 16);
    buf[0] = sequence;
    return [NSData dataWithBytes:buf length:16];
}

- (BOOL)isConnected {
    return _connectState == StateConnected;
}

- (void)gattWrite:(NSData *)data {
    [_writeCondition lock];
    if (![self isConnected]) {
        [_writeCondition unlock];
        return;
    }
    if (DBUG) {
        NSLog(@"Blufi GattWrite Length: %lu,  %@", (unsigned long)data.length, data);
    }
    [_peripheral writeValue:data forCharacteristic:_writeChar type:CBCharacteristicWriteWithResponse];
    [_writeCondition wait];
    [_writeCondition unlock];
    return;
}

- (BOOL)receiveAck:(Byte)expectAck {
    NSLog(@"receiveAck expect: %d", expectAck);
    NSNumber *number = [_deviceAck dequeue];
    if (!number) {
        NSLog(@"receiveAck nil");
        return NO;
    }
    Byte ack = number.intValue;
    NSLog(@"receiveAck: %d", ack);
    return ack == expectAck;
}

- (BOOL)post:(NSData *)data encrypt:(BOOL)encrypt checksum:(BOOL)checksum requireAck:(BOOL)ack type:(Byte)type {
    if (data && data.length > 0) {
        return [self postContainData:data encrypt:encrypt checksum:checksum requireAck:ack type:type];
    } else {
        return [self postEmptyDataWithEncrypt:encrypt checksum:checksum requireAck:ack type:type];
    }
    
    return NO;
}

- (BOOL)postEmptyDataWithEncrypt:(BOOL)encrypt checksum:(BOOL)checksum requireAck:(BOOL)ack type:(Byte)type {
    Byte sequence = [self generateSendSequence];
    NSData *postPacket = [self getPostPacket:nil type:type encrypt:encrypt checksum:checksum requireAck:ack hasFrag:NO sequence:sequence];
    [self gattWrite:postPacket];
    
    return !ack || [self receiveAck:sequence];
}

- (BOOL)postContainData:(NSData *)data encrypt:(BOOL)encrypt checksum:(BOOL)checksum requireAck:(BOOL)ack type:(Byte)type {
    NSInputStream *dataIS = [NSInputStream inputStreamWithData:data];
    NSInteger dataLengthLimit = _postPackageLengthLimit - PACKAGE_HEADER_LENGTH;
    dataLengthLimit -= 2; // If frag, two bytes total length in data
    if (checksum) {
        dataLengthLimit -= 2;
    }
    
    Byte dataBuf[dataLengthLimit];
    NSInteger available = data.length;
    [dataIS open];
    while (dataIS.hasBytesAvailable) {
        NSInteger read = [dataIS read:dataBuf maxLength:dataLengthLimit];
        if (read == 0) {
            break;
        }
        
        NSMutableData *dataContent = [[NSMutableData alloc] init];
        available -= read;
        [dataContent appendBytes:dataBuf length:read];
        if (available > 0 && available <= 2) {
            Byte last[available];
            read = [dataIS read:last maxLength:available];
            if (read != available) {
                // Impossiable come here
                NSLog(@"postContainData: read last bytes error: read=%ld, expect=%ld", (long)read, (long)available);
            }
            [dataContent appendBytes:last length:available];
            available -= read;
        }
        BOOL frag = dataIS.hasBytesAvailable;
        if (frag) {
            NSInteger totalLen = dataContent.length + available;
            NSMutableData *newDataContent = [[NSMutableData alloc] init];
            Byte totalLenBytes[] = {totalLen & 0xff, totalLen >> 8 & 0xff};
            [newDataContent appendBytes:totalLenBytes length:2];
            [newDataContent appendData:dataContent];
            dataContent = newDataContent;
        }
        Byte sequence = [self generateSendSequence];
        NSData *postPacket = [self getPostPacket:dataContent type:type encrypt:encrypt checksum:checksum requireAck:ack hasFrag:frag sequence:sequence];
        
        [self gattWrite:postPacket];
        if (frag) {
            if (ack && ![self receiveAck:sequence]) {
                [dataIS close];
                return NO;
            }
            [NSThread sleepForTimeInterval:0.01];
        } else {
            [dataIS close];
            return !ack || [self receiveAck:sequence];
        }
    }
    [dataIS close];
    return YES;
}

- (NSData *)getPostPacket:(NSData *)data type:(Byte)type encrypt:(BOOL)encrypt checksum:(BOOL)checksum requireAck:(BOOL)ack hasFrag:(BOOL)hasFrag sequence:(Byte)sequence {
    NSMutableData *result = [[NSMutableData alloc] init];
    
    Byte dataLength = data ? data.length : 0;
    Byte frameCtrl = [BlufiFrameCtrlData getFrameCtrlValueWithEncrypted:encrypt checksum:checksum direction:DataOutput requireAck:ack hasFrag:hasFrag];
    
    Byte header[] = {type, frameCtrl, sequence, dataLength};
    [result appendBytes:header length:4];
    
    NSData *checksumData = nil;
    if (checksum) {
        Byte buf[] = {sequence, dataLength};
        NSInteger crc = [BlufiSecurity crc:0 buf:buf length:2];
        if (dataLength > 0) {
            crc = [BlufiSecurity crc:crc data:data];
        }
        
        buf[0] = crc & 0xff;
        buf[1] = crc >> 8 & 0xff;
        checksumData = [NSData dataWithBytes:buf length:2];
    }
    
    if (encrypt && data && data.length > 0) {
        NSData *iv = [self generateAESIV:sequence];
        data = [BlufiSecurity aesEncrypt:data key:_aesKey iv:iv];
    }
    if (data && data.length > 0) {
        [result appendData:data];
    }
    if (checksumData) {
        [result appendData:checksumData];
    }
    
    return result;
}

- (NotifyStatus)parseNotification:(NSData *)response notification:(BlufiNotifyData *)notification {
    if (!response) {
        NSLog(@"parseNotification nil response");
        return NotifyNull;
    }
    if (DBUG) {
        NSLog(@"Notification: %@", response);
    }
    
    if (response.length < 4) {
        NSLog(@"parseNotification invalid length");
        return NotifyInvalidLength;
    }
    
    Byte *buf = (Byte *)response.bytes;
    Byte sequence = buf[2];
    Byte expectSequence = (++_readSequence) & 0xff;
    if (sequence != expectSequence) {
        NSLog(@"parseNotification invalid sequence");
        return NotifyInvalidSequence;
    }
    
    Byte type = buf[0];
    PackageType pkgType = [self getPackageTypeWithTypeValue:type];
    SubType subType = [self getSubTypeWithTypeValue:type];
    notification.typeValue = type;
    notification.packageType = pkgType;
    notification.subType = subType;
    
    Byte frameCtrl = buf[1];
    notification.frameCtrl = frameCtrl;
    BlufiFrameCtrlData *frameCtrlData = [[BlufiFrameCtrlData alloc] initWithValue:frameCtrl];
    
    Byte dataLen = buf[3];
    Byte dataBuf[dataLen];
    Byte dataOffset = 4;
    if (dataLen + dataOffset > response.length) {
        NSLog(@"parseNotification invalid data length");
        return NotifyError;
    }
    memcpy(dataBuf, buf + dataOffset, dataLen);
    NSData *data = [NSData dataWithBytes:dataBuf length:dataLen];
    
    if (frameCtrlData.isEncrypted) {
        NSData *iv =[self generateAESIV:sequence];
        data = [BlufiSecurity aesDecrypt:data key:_aesKey iv:iv];
        memcpy(dataBuf, data.bytes, data.length);
    }
    
    if (frameCtrlData.isChecksum) {
        Byte respChecksum1 = buf[response.length - 1];
        Byte respChecksum2 = buf[response.length - 2];
        
        Byte checkBuf[] = {sequence, dataLen};
        NSInteger crc = [BlufiSecurity crc:0 buf:checkBuf length:2];
        crc = [BlufiSecurity crc:crc data:data];
        Byte calcChecksum1 = crc >> 8 & 0xff;
        Byte calcChecksum2 = crc & 0xff;
        
        if (respChecksum1 != calcChecksum1 || respChecksum2 != calcChecksum2) {
            NSLog(@"parseNotification invalid checksum");
            return NotifyInvalidChecsum;
        }
    }
    
    NSData *appendData;
    if (frameCtrlData.hasFrag) {
        Byte dataSegment[dataLen - 2];
        memcpy(dataSegment, dataBuf + 2, dataLen - 2);
        appendData = [NSData dataWithBytes:dataSegment length:dataLen - 2];
    } else {
        appendData = [NSData dataWithBytes:dataBuf length:dataLen];
    }
    
    [notification appendData:appendData];
    
    return frameCtrlData.hasFrag ? NotifyHasFrag : NotifyComplete;
}

- (void)parseBlufiNotifyData:(BlufiNotifyData *)data {
    PackageType pkgType = data.packageType;
    SubType subType = data.subType;
    NSData *dataContent = data.getData;
    
    if (_blufiDelegate && [_blufiDelegate respondsToSelector:@selector(blufi:gattNotification:packageType:subType:)]) {
        BOOL complete = [_blufiDelegate blufi:self gattNotification:dataContent packageType:pkgType subType:subType];
        if (complete) {
            return;
        }
    }
    
    switch (pkgType) {
        case PackageCtrl:
            [self parseCtrlData:dataContent subType:subType];
            break;
        case PackageData:
            [self parseDataData:dataContent subType:subType];
            break;
    }
}

- (void)parseCtrlData:(NSData *)data subType:(SubType)subType {
    if (subType == CtrlSubTypeAck) {
        [self parseAck:data];
    }
}

- (void)parseDataData:(NSData *)data subType:(SubType)subType {
    switch (subType) {
        case DataSubTypeNeg:
            if (!_closed) {
                [_deviceKey enqueue:data];
            }
            break;
        case DataSubTypeVersion:
            [self parseVersion:data];
            break;
        case DataSubTypeWiFiConnectionState:
            [self parseWifiState:data];
            break;
        case DataSubTypeWiFiList:
            [self parseWiFiScanList:data];
            break;
        case DataSubTypeCustomData:
            [self onReceiveCustomData:data status:StatusSuccess];
            break;
        case DataSubTypeError: {
            NSInteger errCode = data.length > 0 ? ((Byte *)data.bytes)[0] : 300;
            [self onError:errCode];
        }
            break;
    }
}

- (void)parseAck:(NSData *)data {
    int ack = 0x100;
    if (data.length > 0) {
        ack = ((Byte *)data.bytes)[0];
    }
    [_deviceAck enqueue:[NSNumber numberWithInt:ack]];
}

- (void)onVersionResponse:(BlufiVersionResponse *)response status:(BlufiStatusCode)code {
    id delegate = _blufiDelegate;
    BlufiClient *client = self;
    if (delegate && [delegate respondsToSelector:@selector(blufi:didReceiveDeviceVersionResponse:status:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate blufi:client didReceiveDeviceVersionResponse:response status:code];
        }];
    }
}

- (void)parseVersion:(NSData *)data {
    BlufiStatusCode code;
    BlufiVersionResponse *response;
    Byte *buf = (Byte *)data.bytes;
    if (data.length != 2) {
        code = StatusInvalidData;
        response = nil;
    } else {
        code = StatusSuccess;
        response = [[BlufiVersionResponse alloc] init];
        response.bigVer = buf[0];
        response.smallVer = buf[1];
    }
    
    [self onVersionResponse:response status:code];
}

- (void)onDeviceStatusResponse:(BlufiStatusResponse *)response status:(BlufiStatusCode)code {
    id delegate = _blufiDelegate;
    BlufiClient *client = self;
    if (delegate && [delegate respondsToSelector:@selector(blufi:didReceiveDeviceStatusResponse:status:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate blufi:client didReceiveDeviceStatusResponse:response status:code];
        }];
    }
}

- (void)parseWifiState:(NSData *)data {
    BlufiStatusCode code;
    BlufiStatusResponse *response;
    if (data.length < 3) {
        code = StatusInvalidData;
        response = nil;
    } else {
        code = StatusSuccess;
        response = [[BlufiStatusResponse alloc] init];
        
        Byte temp[data.length];
        NSInputStream *dataIS = [NSInputStream inputStreamWithData:data];
        [dataIS open];
        
        [dataIS read:temp maxLength:1];
        response.opMode = temp[0];
        
        [dataIS read:temp maxLength:1];
        response.staConnectionStatus = temp[0];
        
        [dataIS read:temp maxLength:1];
        response.softApConnectionCount = temp[0];
        
        while (dataIS.hasBytesAvailable) {
            NSInteger read = [dataIS read:temp maxLength:2];
            if (read != 2) {
                NSLog(@"parseWifiState contain invalid data1");
                code = StatusInvalidData;
                break;
            }
            Byte infoType = temp[0];
            Byte len = temp[1];
            read = [dataIS read:temp maxLength:len];
            if (read != len) {
                NSLog(@"parseWifiState contain invalid data2");
                code = StatusInvalidData;
                break;
            }
            [self parseWifiStateData:temp length:len type:infoType response:response];
        }
        
        [dataIS close];
    }
    
    [self onDeviceStatusResponse:response status:code];
}

- (void)parseWifiStateData:(Byte *)data length:(NSInteger)length type:(Byte)infoType response:(BlufiStatusResponse *)response {
    switch (infoType) {
        case DataSubTypeStaBssid: {
            NSString *bssid = [self hexFromBytes:data length:length];
            response.staBssid = bssid;
        }
            break;
        case DataSubTypeStaSsid: {
            NSString *ssid = [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
            response.staSsid = ssid;
        }
            break;
        case DataSubTypeStaPassword: {
            NSString *password = [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
            response.staPassword = password;
        }
            break;
        case DataSubTypeSoftAPAuthMode:
            response.softApSecurity = data[0];
            break;
        case DataSubTypeSoftAPChannel:
            response.softApChannel = data[0];
            break;
        case DataSubTypeSoftAPMaxConnection:
            response.softApMaxConnection = data[0];
            break;
        case DataSubTypeSoftAPPassword: {
            NSString *password = [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
            response.softApPassword = password;
        }
            break;
        case DataSubTypeSoftAPSsid: {
            NSString *ssid = [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
            response.softApSsid = ssid;
        }
            break;
    }
}

- (void)onDeviceScanList:(NSMutableArray<BlufiScanResponse *> *)list status:(BlufiStatusCode)code {
    id delegate = _blufiDelegate;
    BlufiClient *client = self;
    if (delegate && [delegate respondsToSelector:@selector(blufi:didReceiveDeviceScanResponse:status:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate blufi:client didReceiveDeviceScanResponse:list status:StatusSuccess];
        }];
    }
}

- (void)parseWiFiScanList:(NSData *)data {
    NSMutableArray<BlufiScanResponse *> *result = [NSMutableArray array];
    
    NSInputStream *dataIS = [NSInputStream inputStreamWithData:data];
    Byte temp[data.length];
    [dataIS open];
    while (dataIS.hasBytesAvailable) {
        NSInteger read = [dataIS read:temp maxLength:2];
        if (read != 2) {
            NSLog(@"parseWiFiScanList contain invalid data1");
            break;
        }
        Byte length = temp[0];
        if (length < 1) {
            NSLog(@"parseWiFiScanList invalid length");
            break;
        }
        Byte rssi = temp[1];
        read = [dataIS read:temp maxLength:length - 1];
        if (read != length - 1) {
            NSLog(@"parseWiFiScanList invalid ssid data");
            break;
        }
        NSString *ssid = [[NSString alloc] initWithBytes:temp length:length - 1 encoding:NSUTF8StringEncoding];
        
        BlufiScanResponse *response = [[BlufiScanResponse alloc] init];
        response.type = 0x01;
        response.rssi = rssi;
        response.ssid = ssid;
        [result addObject:response];
    }
    [dataIS close];
    
    [self onDeviceScanList:result status:StatusSuccess];
}

- (void)onError:(NSInteger)errCode {
    id delegate = _blufiDelegate;
    BlufiClient *client = self;
    if (delegate && [delegate respondsToSelector:@selector(blufi:didReceiveError:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate blufi:client didReceiveError:errCode];
        }];
    }
}

- (void)onPostCustomData:(NSData *)data status:(BlufiStatusCode)code {
    id delegate = _blufiDelegate;
    BlufiClient *client = self;
    if (delegate && [delegate respondsToSelector:@selector(blufi:didPostCustomData:status:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate blufi:client didPostCustomData:data status:code];
        }];
    }
}

- (void)onReceiveCustomData:(NSData *)data status:(BlufiStatusCode)code {
    id delegate = _blufiDelegate;
    BlufiClient *client = self;
    if (delegate && [delegate respondsToSelector:@selector(blufi:didReceiveCustomData:status:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate blufi:client didReceiveCustomData:data status:code];
        }];
    }
}

- (void)requestCloseConnection {
    [_requestQueue addOperationWithBlock:^{
        Byte type = [self getTypeValueWithPackageType:PackageCtrl subType:CtrlSubTypeCloseConnection];
        [self post:nil encrypt:NO checksum:NO requireAck:NO type:type];
    }];
}

- (void)requestDeviceVersion {
    BOOL encrypted = _encrypted;
    BOOL checksum = _checksum;
    [_requestQueue addOperationWithBlock:^{
        Byte type = [self getTypeValueWithPackageType:PackageCtrl subType:CtrlSubTypeGetVersion];
        BOOL posted = [self post:nil encrypt:encrypted checksum:checksum requireAck:false type:type];
        if (!posted) {
            NSLog(@"Post DeiviceVersion request failed");
            [self onVersionResponse:nil status:StatusWriteFailed];
        }
    }];
}

- (void)requestDeviceStatus {
    BOOL encrypted = _encrypted;
    BOOL checksum = _checksum;
    [_requestQueue addOperationWithBlock:^{
        Byte type = [self getTypeValueWithPackageType:PackageCtrl subType:CtrlSubTypeGetWiFiStatus];
        BOOL posted = [self post:nil encrypt:encrypted checksum:checksum requireAck:false type:type];
        if (!posted) {
            NSLog(@"Post DeviceStatus request failed");
            [self onDeviceStatusResponse:nil status:StatusWriteFailed];
        }
    }];
}

- (void)requestDeviceScan {
    BOOL encrypted = _encrypted;
    BOOL checksum = _checksum;
    [_requestQueue addOperationWithBlock:^{
        Byte type = [self getTypeValueWithPackageType:PackageCtrl subType:CtrlSubTypeGetWiFiList];
        BOOL posted = [self post:nil encrypt:encrypted checksum:checksum requireAck:false type:type];
        if (!posted) {
            NSLog(@"Post WiFiScan request failed");
            [self onDeviceScanList:nil status:StatusWriteFailed];
        }
    }];
}

- (void)postCustomData:(NSData *)data {
    BOOL encrypted = _encrypted;
    BOOL checksum = _checksum;
    BOOL ack = _requireAck;
    [_requestQueue addOperationWithBlock:^{
        Byte type = [self getTypeValueWithPackageType:PackageData subType:DataSubTypeCustomData];
        BOOL posted = [self post:data encrypt:encrypted checksum:checksum requireAck:ack type:type];
        BlufiStatusCode code = posted ? StatusSuccess : StatusWriteFailed;
        [self onPostCustomData:data status:code];
    }];
}

- (void)onPostConfigureParams:(BlufiStatusCode)code {
    id delegate = _blufiDelegate;
    BlufiClient *client = self;
    if (delegate && [delegate respondsToSelector:@selector(blufi:didPostConfigureParams:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate blufi:client didPostConfigureParams:code];
        }];
    }
}

- (BOOL)postDeviceMode:(OpMode)opMode {
    Byte type = [self getTypeValueWithPackageType:PackageCtrl subType:CtrlSubTypeSetOpMode];
    Byte buf[] = {opMode};
    NSData *data = [NSData dataWithBytes:buf length:1];
    return [self post:data encrypt:_encrypted checksum:_checksum requireAck:YES type:type];
}

- (BOOL)postStaInfo:(BlufiConfigureParams *)params {
    Byte type = [self getTypeValueWithPackageType:PackageData subType:DataSubTypeStaSsid];
    NSData *ssid = [params.staSsid dataUsingEncoding:NSUTF8StringEncoding];
    if (![self post:ssid encrypt:_encrypted checksum:_checksum requireAck:_requireAck type:type]) {
        return NO;
    }
    [NSThread sleepForTimeInterval:0.01];
    
    type = [self getTypeValueWithPackageType:PackageData subType:DataSubTypeStaPassword];
    NSData *password = [params.staPassword dataUsingEncoding:NSUTF8StringEncoding];
    if (![self post:password encrypt:_encrypted checksum:_checksum requireAck:_requireAck type:type]) {
        return NO;
    }
    [NSThread sleepForTimeInterval:0.01];
    
    type = [self getTypeValueWithPackageType:PackageCtrl subType:CtrlSubTypeConnectWiFi];
    return [self post:nil encrypt:_encrypted checksum:_checksum requireAck:_requireAck type:type];
}

- (BOOL)postSoftAPInfo:(BlufiConfigureParams *)params {
    NSData *ssid = params.softApSsid ? [params.softApSsid dataUsingEncoding:NSUTF8StringEncoding] : nil;
    if (ssid && ssid.length > 0) {
        Byte type = [self getTypeValueWithPackageType:PackageData subType:DataSubTypeSoftAPSsid];
        if (![self post:ssid encrypt:_encrypted checksum:_checksum requireAck:_requireAck type:type]) {
            return NO;
        }
        [NSThread sleepForTimeInterval:0.01];
    }
    
    NSData *password = params.softApPassword ? [params.softApPassword dataUsingEncoding:NSUTF8StringEncoding] : nil;
    if (password && password.length > 0) {
        Byte type = [self getTypeValueWithPackageType:PackageData subType:DataSubTypeSoftAPPassword];
        if (![self post:password encrypt:_encrypted checksum:_checksum requireAck:_requireAck type:type]) {
            return NO;
        }
        [NSThread sleepForTimeInterval:0.01];
    }
    
    NSInteger channel = params.softApChannel;
    if (channel > 0) {
        Byte type = [self getTypeValueWithPackageType:PackageData subType:DataSubTypeSoftAPChannel];
        Byte buf[] = {channel};
        NSData *data = [NSData dataWithBytes:buf length:1];
        if (![self post:data encrypt:_encrypted checksum:_checksum requireAck:_requireAck type:type]) {
            return NO;
        }
        [NSThread sleepForTimeInterval:0.01];
    }
    
    NSInteger maxConn = params.softApMaxConnection;
    if (maxConn > 0) {
        Byte type = [self getTypeValueWithPackageType:PackageData subType:DataSubTypeSoftAPMaxConnection];
        Byte buf[] = {maxConn};
        NSData *data = [NSData dataWithBytes:buf length:1];
        if (![self post:data encrypt:_encrypted checksum:_checksum requireAck:_requireAck type:type]) {
            return NO;
        }
        [NSThread sleepForTimeInterval:0.01];
    }
    
    Byte type = [self getTypeValueWithPackageType:PackageData subType:DataSubTypeSoftAPAuthMode];
    Byte buf[] = {(Byte)params.softApSecurity};
    NSData *data = [NSData dataWithBytes:buf length:1];
    return [self post:data encrypt:_encrypted checksum:_checksum requireAck:_requireAck type:type];
}

- (void)configure:(BlufiConfigureParams *)params {
    [_requestQueue addOperationWithBlock:^{
        OpMode opMode  = params.opMode;
        switch (opMode) {
            case OpModeNull:
                if (![self postDeviceMode:opMode]) {
                    [self onPostConfigureParams:StatusWriteFailed];
                    return;
                }
                [self onPostConfigureParams:StatusSuccess];
                break;
            case OpModeSta:
                if (![self postDeviceMode:opMode]) {
                    [self onPostConfigureParams:StatusWriteFailed];
                    return;
                }
                if (![self postStaInfo:params]) {
                    [self onPostConfigureParams:StatusWriteFailed];
                    return;
                }
                [self onPostConfigureParams:StatusSuccess];
                break;
            case OpModeSoftAP:
                if (![self postDeviceMode:opMode]) {
                    [self onPostConfigureParams:StatusWriteFailed];
                    return;
                }
                if (![self postSoftAPInfo:params]) {
                    [self onPostConfigureParams:StatusWriteFailed];
                    return;
                }
                [self onPostConfigureParams:StatusSuccess];
                break;
            case OpModeStaSoftAP:
                if (![self postDeviceMode:opMode]) {
                    [self onPostConfigureParams:StatusWriteFailed];
                    return;
                }
                if (![self postStaInfo:params]) {
                    [self onPostConfigureParams:StatusWriteFailed];
                    return;
                }
                if (![self postSoftAPInfo:params]) {
                    [self onPostConfigureParams:StatusWriteFailed];
                    return;
                }
                [self onPostConfigureParams:StatusSuccess];
                break;
            default:
                NSLog(@"configure invalid OpMode: %d", opMode);
                [self onPostConfigureParams:StatusInvalidRequest];
                break;
        }
    }];
}

- (BlufiDH *)postNegotiateSecurity {
    Byte type = [self getTypeValueWithPackageType:PackageData subType:DataSubTypeNeg];
    BlufiDH *blufiDH = [BlufiSecurity dhGenerateKeys];
    NSData *p = blufiDH.p;
    NSData *g = blufiDH.g;
    NSData *k = blufiDH.publicKey;
    NSInteger pgkLength = p.length + g.length + k.length + 6;
    Byte bytes[] = {
        NegSecuritySetTotalLength,
        pgkLength >> 8 & 0xff,
        pgkLength & 0xff
    };
    BOOL posted = [self post:[NSData dataWithBytes:bytes length:3] encrypt:NO checksum:NO requireAck:_requireAck type:type];
    if (!posted) {
        NSLog(@"postNegotiateSecurity: Post length failed");
        return nil;
    }
    
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:pgkLength];
    Byte negType[] = {NegSecuritySetAllData};
    [data appendBytes:negType length:1];
    
    Byte pLength[] = {p.length >> 8 & 0xff, p.length & 0xff};
    [data appendBytes:pLength length:2];
    [data appendData:p];
    
    Byte gLength[] = {g.length >> 8 & 0xff, g.length & 0xff};
    [data appendBytes:gLength length:2];
    [data appendData:g];
    
    Byte kLength[] = {k.length >> 8 & 0xff, k.length & 0xff};
    [data appendBytes:kLength length:2];
    [data appendData:k];
    
    posted = [self post:data encrypt:NO checksum:NO requireAck:_requireAck type:type];
    if (!posted) {
        NSLog(@"postNegotiateSecurity: Post data failed");
        return nil;
    }
    
    return blufiDH;
}

- (BOOL)postSetSecurityCtrlEncrypted:(BOOL)ctrlEncrypted ctrlChecksum:(BOOL)ctrlChecksum dataEncrypted:(BOOL)dataEncrypted dataChecksum:(BOOL)dataChecksum {
    Byte type = [self getTypeValueWithPackageType:PackageCtrl subType:CtrlSubTypeSetSecurityMode];
    Byte data = 0;
    if (dataChecksum) {
        data |= 1;
    }
    if (dataEncrypted) {
        data |= 0b10;
    }
    if (ctrlChecksum) {
        data |= 0b10000;
    }
    if (ctrlEncrypted) {
        data |= 0b100000;
    }
    Byte postBytes[] = {data};
    NSData *postData = [NSData dataWithBytes:postBytes length:1];
    return [self post:postData encrypt:NO checksum:YES requireAck:_requireAck type:type];
}

- (void)onNegotiateSecurityResult:(BlufiStatusCode)code {
    id delegate = _blufiDelegate;
    BlufiClient *client = self;
    if (delegate && [delegate respondsToSelector:@selector(blufi:didNegotiateSecurity:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate blufi:client didNegotiateSecurity:code];
        }];
    }
}

- (void)negotiateSecurity {
    [_requestQueue addOperationWithBlock:^{
        BOOL setSecurity = NO;
        BlufiStatusCode code = StatusFailed;
        @try {
            BlufiDH *blufiDH = [self postNegotiateSecurity];
            if (!blufiDH) {
                code = StatusWriteFailed;
                return;
            }
            NSLog(@"negotiateSecurity DH posted");
            
            NSData *deviceKey = [self.deviceKey dequeue];
            if (!deviceKey) {
                NSLog(@"negotiateSecurity Recevie nil deviceKey");
                code = StatusFailed;
                return;
            }
            
            NSData *secretKey = [blufiDH generateSecret:deviceKey];
            self.aesKey = [BlufiSecurity md5:secretKey];
            if (DBUG) {
                NSLog(@"DH Secret = %@", secretKey);
                NSLog(@"AES Key   = %@", self.aesKey);
            }
            
            setSecurity = [self postSetSecurityCtrlEncrypted:NO ctrlChecksum:NO dataEncrypted:YES dataChecksum:YES];
            if (!setSecurity) {
                NSLog(@"negotiateSecurity postSetSecurity failed");
                code = StatusWriteFailed;
            }
        } @catch (NSException *exception) {
            NSLog(@"negotiateSecurity exception: %@", exception);
            code = StatusException;
        } @finally {
            if (setSecurity) {
                self.encrypted = YES;
                self.checksum = YES;
                [self onNegotiateSecurityResult:StatusSuccess];
            } else {
                self.encrypted = NO;
                self.checksum = NO;
                [self onNegotiateSecurityResult:code];
            }
        }
    }];
}

- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    _blePowerOn = central.state == CBManagerStatePoweredOn;
    if (_blePowerOn) {
        NSLog(@"Blufi Client BLE state pwoered on");
        if (_bleConnectMark) {
            _bleConnectMark = NO;
            [self scanBLE];
        }
    }
    id delegate = _centralManagerDelete;
    if (delegate) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate centralManagerDidUpdateState:central];
        }];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
//    NSLog(@"Per UUID: %@, %@", peripheral.name, peripheral.identifier.UUIDString)
    if ([peripheral.identifier isEqual:_identifier]) {
        [_centralManager stopScan];
        _peripheral = peripheral;
        _peripheral.delegate = self;
        
        [_centralManager connectPeripheral:peripheral options:nil];
    }
    
    // callback
    id delegate = _centralManagerDelete;
    if (delegate && [delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate centralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
        }];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    // Connect BLE successfully
    CBUUID *uuid = [CBUUID UUIDWithString:UUID_SERVICE];
    NSArray<CBUUID *> *filters = @[uuid];
    [peripheral discoverServices:filters];
    
    _connectState = StateConnected;
    // callback
    id delegate = _centralManagerDelete;
    if (delegate && [delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate centralManager:central didConnectPeripheral:peripheral];
        }];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // Connect BLE failed
    [self clearConnection];
    
    // callback
    id delegate = _centralManagerDelete;
    if (delegate && [delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate centralManager:central didFailToConnectPeripheral:peripheral error:error];
        }];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // Disconnect BLE
    [self clearConnection];
    
    // callback
    id delegate = _centralManagerDelete;
    if (delegate && [delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate centralManager:central didDisconnectPeripheral:peripheral error:error];
        }];
    }
}

- (void)gattDiscoverCallback {
    id bDelegage = _blufiDelegate;
    if (bDelegage && [bDelegage respondsToSelector:@selector(blufi:gattPrepared:service:writeChar:notifyChar:)]) {
        BlufiClient *client = self;
        CBService *service = _service;
        CBCharacteristic *writeChar = _writeChar;
        CBCharacteristic *notifyChar = _notifyChar;
        BlufiStatusCode code = service && writeChar && notifyChar ? StatusSuccess : StatusFailed;
        [_callbackQueue addOperationWithBlock:^{
            [bDelegage blufi:client gattPrepared:code service:service writeChar:writeChar notifyChar:notifyChar];
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    // Discover services
    if (error) {
        NSLog(@"didDiscoverServices error: %@", error);
        [self clearConnection];
        [self gattDiscoverCallback];
    } else {
        NSArray<CBService *> *services = [peripheral services];
        for (CBService *service in services) {
            if ([service.UUID.UUIDString isEqualToString:UUID_SERVICE]) {
                _service = service;
                break;
            }
        }
        if (_service) {
            CBService *service  = services[0];
            [peripheral discoverCharacteristics:nil forService:service];
            _service = service;
        } else {
            NSLog(@"didDiscoverServices failed");
            [self gattDiscoverCallback];
            [self clearConnection];
        }
    }
    
    // callback
    id deletgate = _peripheralDelegate;
    if (deletgate && [deletgate respondsToSelector:@selector(peripheral:didDiscoverServices:)]) {
        [deletgate peripheral:peripheral didDiscoverServices:error];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // Discover Characteristics
    if (error) {
        NSLog(@"didDiscoverCharacteristicsForService error: %@", error);
        [self gattDiscoverCallback];
        [self clearConnection];
    } else {
        CBCharacteristic *writeChar = nil;
        CBCharacteristic *notifyChar = nil;
        NSArray<CBCharacteristic *> *characteristics = [service characteristics];
        for (CBCharacteristic *c in characteristics) {
            if ([c.UUID isEqual:_writeUUID]) {
                NSLog(@"didDiscoverCharacteristicsForService get write char");
                writeChar = c;
            } else if ([c.UUID isEqual:_notifyUUID]) {
                NSLog(@"didDiscoverCharacteristicsForService get notify char");
                notifyChar = c;
            }
        }
        _writeChar = writeChar;
        _notifyChar = notifyChar;
        if (!writeChar || !notifyChar) {
            NSLog(@"didDiscoverCharacteristicsForService failed");
            [self gattDiscoverCallback];
            [self clearConnection];
        } else {
            [peripheral setNotifyValue:YES forCharacteristic:notifyChar];
        }
    }
    
    // callback
    id deletgate = _peripheralDelegate;
    if (deletgate && [deletgate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [deletgate peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    // Set Notification
    if (error) {
        NSLog(@"didUpdateNotificationStateForCharacteristic error: %@", error);
        [self gattDiscoverCallback];
        [self clearConnection];
    } else {
            // Connection all ready
        [self gattDiscoverCallback];
    }
    
    // callback
    id pDelegete = _peripheralDelegate;
    if (pDelegete && [pDelegete respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [pDelegete peripheral:peripheral didUpdateNotificationStateForCharacteristic:characteristic error:error];
        }];
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic error: %@", error);
        [self clearConnection];
    } else {
        if (!_notifyData) {
            _notifyData = [[BlufiNotifyData alloc] init];
        }
        NSData *value = characteristic.value;
        NotifyStatus status = [self parseNotification:value notification:_notifyData];
        switch (status) {
            case NotifyComplete:
                [self parseBlufiNotifyData:_notifyData];
                _notifyData = nil;
                break;
            case NotifyHasFrag:
                NSLog(@"parseNotification wait next");
                break;
            default:
                NSLog(@"parseNotification failed");
                [self onError:StatusInvalidData];
                break;
        }
    }
    
    // callback
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:error];
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    [_writeCondition lock];
    [_writeCondition signal];
    [_writeCondition unlock];
    if (error) {
        NSLog(@"didWriteValueForCharacteristic error: %@", error);
        [self clearConnection];
    }
    
    // callback
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
        }];
    }
}


// Blufi unused delegate functions Start
// CBCentralManager delegate Start

//- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict {
//    id delegate = _centralManagerDelete;
//    if (delegate && [delegate respondsToSelector:@selector(centralManager:willRestoreState:)]) {
//        [_callbackQueue addOperationWithBlock:^{
//            [delegate centralManager:central willRestoreState:dict];
//        }];
//    }
//}

- (void)centralManager:(CBCentralManager *)central connectionEventDidOccur:(CBConnectionEvent)event forPeripheral:(CBPeripheral *)peripheral {
    if (@available(iOS 13.0, *)) {
        id delegate = _centralManagerDelete;
        if (delegate && [delegate respondsToSelector:@selector(centralManager:connectionEventDidOccur:forPeripheral:)]) {
            [_callbackQueue addOperationWithBlock:^{
                [delegate centralManager:central connectionEventDidOccur:event forPeripheral:peripheral];
            }];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didUpdateANCSAuthorizationForPeripheral:(CBPeripheral *)peripheral {
    if (@available(iOS 13.0, *)) {
        id delegate = _centralManagerDelete;
        if (delegate && [delegate respondsToSelector:@selector(centralManager:didUpdateANCSAuthorizationForPeripheral:)]) {
            [_callbackQueue addOperationWithBlock:^{
                [delegate centralManager:central didUpdateANCSAuthorizationForPeripheral:peripheral];
            }];
        }
    }
}
// CBCentralManager delegate End

// CBPeripheral delegate Start
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheralDidUpdateName:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheralDidUpdateName:peripheral];
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheral:didModifyServices:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheral:peripheral didModifyServices:invalidatedServices];
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheral:didReadRSSI:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheral:peripheral didReadRSSI:RSSI error:error];
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error {
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheral:didDiscoverIncludedServicesForService:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheral:peripheral didDiscoverIncludedServicesForService:service error:error];
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheral:peripheral didDiscoverDescriptorsForCharacteristic:characteristic error:error];
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheral:peripheral didUpdateValueForDescriptor:descriptor error:error];
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheral:didWriteValueForDescriptor:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheral:peripheral didWriteValueForDescriptor:descriptor error:error];
        }];
    }
}

- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheralIsReadyToSendWriteWithoutResponse:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheralIsReadyToSendWriteWithoutResponse:peripheral];
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didOpenL2CAPChannel:(CBL2CAPChannel *)channel error:(NSError *)error  API_AVAILABLE(ios(11.0)){
    id delegate = _peripheralDelegate;
    if (delegate && [delegate respondsToSelector:@selector(peripheral:didOpenL2CAPChannel:error:)]) {
        [_callbackQueue addOperationWithBlock:^{
            [delegate peripheral:peripheral didOpenL2CAPChannel:channel error:error];
        }];
    }
}
// CBPeripheral delegate End


// Blufi unused delegate functions End

@end

@interface EspBlockingQueue()

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSCondition *lock;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

- (NSUInteger)count;

@end

@implementation EspBlockingQueue

- (id)init {
    self = [super init];
    if (self) {
        self.queue = [[NSMutableArray alloc] init];
        self.lock = [[NSCondition alloc] init];
        self.dispatchQueue = dispatch_queue_create("com.espressif.blufi", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)cancel {
    [_lock lock];
    [_lock signal];
    [_lock unlock];
}

- (void)enqueue:(id)object {
    [_lock lock];
    [_queue addObject:object];
    [_lock signal];
    [_lock unlock];
}

- (id)dequeue {
    __block id object;
    dispatch_sync(_dispatchQueue, ^{
        [self.lock lock];
        while (self.queue.count == 0) {
            [self.lock wait];
        }
        object = [self.queue objectAtIndex:0];
        [self.queue removeObjectAtIndex:0];
        [self.lock unlock];
    });
    NSLog(@"device details object %@",object);
    return object;
}

- (NSUInteger)count {
    return [_queue count];
}

- (void)dealloc {
    self.dispatchQueue = nil;
    self.queue = nil;
    self.lock = nil;
}

@end
