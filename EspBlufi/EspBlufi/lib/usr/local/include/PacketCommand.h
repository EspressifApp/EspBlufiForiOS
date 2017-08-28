//
//  PacketCommand.h
//  EspBlufi
//
//  Created by zhiweijian on 23/03/2017.
//  Copyright © 2017 zhi weijian. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef enum
{
   OPEN_Mode=0x00,
   WEP_Mode=0x01,
   WPA_PSK_Mode=0x02,
   WPA2_PSK_Mode=0x03,
   WPA_WPA2_PSK=0X04,
}AuthenticationMode;

typedef enum
{
    NullOpmode=0x00,
    STAOpmode=0x01,
    SoftAPOpmode=0x02,
    SoftAP_STAOpmode=0x03,
    UnknownOpmode,
}Opmode;
//低2bit
typedef enum  {
    ContolType=0x0,
    DataType=0x1,
} Type;

//高6bit
typedef enum  {
    ACK_Esp32_Phone_ControlSubType=0x0,
    ESP32_Phone_Security_ControlSubType=0x1,
    Wifi_Op_ControlSubType=0x2,
    Connect_AP_ControlSubType=0x3,
    Disconnect_AP_ControlSubType=0x4,
    Get_Wifi_Status_ControlSubType=0x5,
    Deauthenticate_STA_Device_SoftAP_ControlSubType=0x6,
    Get_Version_ControlSubType=0x7,
    Negotiate_Data_ControlSubType=0x8,
} ControlSubType;

//高6bit
typedef enum  {
    Negotiate_Data_DataSubType=0x0,
    BSSID_STA_DataSubType=0x1,
    SSID_STA_DataSubType=0x2,
    Password_STA_DataSubType=0x3,
    SSID_SoftaAP_DataSubType=0x4,
    Password_SoftAP_DataSubType=0x5,
    Max_Connect_Number_SoftAP_DataSubType=0x6,
    Authentication_SoftAP_DataSubType=0x7,
    Channel_SoftAP_DataSubType=0x8,
    Username_DataSubType=0x9,
    CA_Certification_DataSubType=0xa,
    Client_Certification_DataSubType=0xb,
    Server_Certification_DataSubType=0xc,
    Client_PrivateKey_DataSubType=0xd,
    Server_PrivateKey_DataSubType=0xe,
    Wifi_Connection_state_Report_DataSubType=0xf,
    Version_DataSubType=0x10,
} DataSubType;

//包控制域，1个字节，每个bit表示不同的含义
typedef enum  {
    Packet_Hash_FrameCtrlType=0x01,   //包是否加密, 0000 0001
    Data_End_Checksum_FrameCtrlType=0x02, //data域结尾是否包含校验, 0000 0010
    Data_Direction_FrameCtrlType=0x04, //数据方向, 0000,0100
    ACK_FrameCtrlType=0x08, //是否回复ACK, 0000 1000
    Append_Data_FrameCtrlType=0x10, //是否有后续的Frag包, 0001 0000
    
} FrameCtrlType;


@class RSAObject;

@interface PacketCommand : NSObject
//CRC16验证
+(BOOL)VerifyCRCWithData:(NSData *)data;
//取得校验值
+(NSData *)GetCRCWithData:(NSData *)data;
//回复ACK
+(NSMutableData *)ReturnAckWithSequence:(uint8_t)sequence BackSequence:(uint8_t)backsequence;
//设置Opmode
+(NSMutableData *)SetOpmode:(Opmode)opmode Sequence:(uint8_t)sequence;
//获取wifi信息
+(NSMutableData *)GetDeviceInforWithSequence:(uint8_t)Sequence;
//连接AP
+(NSMutableData *)ConnectToAPWithSequence:(uint8_t)sequence;
//断开连接AP
+(NSMutableData *)DisconnectFromAPWithSequence:(uint8_t)sequence;
//设置STA模式password
+(NSMutableData *)SetStationPassword:(NSString *)password  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
//设置STA模式的ssid
+(NSMutableData *)SetStationSsid:(NSString *)ssid  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
//设置SoftAP模式的ssid
+(NSMutableData *)SetSoftAPSsid:(NSString *)ssid  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
//设置SoftAP模式password
+(NSMutableData *)SetSoftAPPassword:(NSString *)password  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
//设置softAP 的Security
+(NSMutableData *)SetAuthenticationforSoftAP:(AuthenticationMode)mode  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
//设置softAP 的 Channel
+(NSMutableData *)SetChannelforSoftAP:(uint8_t)channel  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
//设置softAP 的 Max connection
+(NSMutableData *)SetMaxConnectforSoftAP:(uint8_t)max  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;
//通知设备安全模式
+(NSMutableData *)SetESP32ToPhoneSecurityWithSecurity:(BOOL)security CheckSum:(BOOL)checksum Sequence:(uint8_t)sequence;
//协商加密数据长度
+(NSMutableData *)SetNegotiatelength:(uint16_t)length Sequence:(uint8_t)sequence;
//协商加密数据内容
+(NSData *)SendNegotiateData:(NSData *)somedata Sequence:(uint8_t)sequence Frag:(BOOL)flag TotalLength:(uint16_t)totallength;
//16进制字符串转nadata
+(NSData *)convertHexStrToData:(NSString *)str;
//生成协商数据data
+(NSData *)GenerateNegotiateData:(RSAObject *)rsaobject;

@end
