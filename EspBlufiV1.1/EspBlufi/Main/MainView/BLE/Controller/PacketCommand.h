//
//  PacketCommand.h
//  EspBlufi
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import <Foundation/Foundation.h>



typedef enum {
   OPEN_Mode        = 0x00,
   WEP_Mode         = 0x01,
   WPA_PSK_Mode     = 0x02,
   WPA2_PSK_Mode    = 0x03,
   WPA_WPA2_PSK     = 0X04,
} AuthenticationMode;

typedef enum {
    NullOpmode       = 0x00,
    STAOpmode        = 0x01,
    SoftAPOpmode     = 0x02,
    SoftAP_STAOpmode = 0x03,
    UnknownOpmode,
} Opmode;

//low 2bit
typedef enum {
    ContolType=0x0,
    DataType=0x1,
} Type;

//high 6bit
typedef enum {
    ACK_Esp32_Phone_ControlSubType                  = 0x00,
    ESP32_Phone_Security_ControlSubType             = 0x01,
    Wifi_Op_ControlSubType                          = 0x02,
    Connect_AP_ControlSubType                       = 0x03,
    Disconnect_AP_ControlSubType                    = 0x04,
    Get_Wifi_Status_ControlSubType                  = 0x05,
    Deauthenticate_STA_Device_SoftAP_ControlSubType = 0x06,
    Get_Version_ControlSubType                      = 0x07,
    Negotiate_Data_ControlSubType                   = 0x08,
} ControlSubType;

//high 6bit
typedef enum {
    Negotiate_Data_DataSubType               = 0x00,
    BSSID_STA_DataSubType                    = 0x01,
    SSID_STA_DataSubType                     = 0x02,
    Password_STA_DataSubType                 = 0x03,
    SSID_SoftaAP_DataSubType                 = 0x04,
    Password_SoftAP_DataSubType              = 0x05,
    Max_Connect_Number_SoftAP_DataSubType    = 0x06,
    Authentication_SoftAP_DataSubType        = 0x07,
    Channel_SoftAP_DataSubType               = 0x08,
    Username_DataSubType                     = 0x09,
    CA_Certification_DataSubType             = 0x0a,
    Client_Certification_DataSubType         = 0x0b,
    Server_Certification_DataSubType         = 0x0c,
    Client_PrivateKey_DataSubType            = 0x0d,
    Server_PrivateKey_DataSubType            = 0x0e,
    Wifi_Connection_state_Report_DataSubType = 0x0f,
    Version_DataSubType                      = 0x10,
    Wifi_List_DataSubType                    = 0x11,
    blufi_error_DataSubType                  = 0x12,
    blufi_custom_DataSubType                 = 0x13,
} DataSubType;

//包控制域，1个字节，每个bit表示不同的含义
typedef enum {
    Packet_Hash_FrameCtrlType       = 0x01, //包是否加密, 0000 0001
    Data_End_Checksum_FrameCtrlType = 0x02, //data has CRC part or not, 0000 0010
    Data_Direction_FrameCtrlType    = 0x04, //数据方向, 0000,0100
    ACK_FrameCtrlType               = 0x08, //swnd ACK or not, 0000 1000
    Append_Data_FrameCtrlType       = 0x10, //是否有后续的Frag包, 0001 0000
} FrameCtrlType;


@class RSAObject;

@interface PacketCommand : NSObject

/**
 *
 * @brief         This function is called to compare CRC16
 * @param data :  data value
 * @return        TRUE - CRC success, FALSE - CRC error
 *
 */
+(BOOL)VerifyCRCWithData:(NSData *)data;

/**
*
* @brief         This function is called to get CRC16 of data
* @param data :  data value
* @return        CRC16 value
*
*/
+(NSData *)GetCRCWithData:(NSData *)data;

/**
 *
 * @brief         This function is called to send ack
 * @param sequence :  current sequence
 * @param sequence :  the sequence of need ack
 * @return        ACK data
 *
 */
+(NSMutableData *)ReturnAckWithSequence:(uint8_t)sequence BackSequence:(uint8_t)backsequence;

/**
 *
 * @brief         This function is called to set opmode
 * @param sequence :  current sequence
 * @param opmode :  opmode
 * @return        ACK data
 *
 */
+(NSMutableData *)SetOpmode:(Opmode)opmode Sequence:(uint8_t)sequence;

/**
 *
 * @brief         This function is called to get wifi information
 * @param sequence :  current sequence
 * @return        data
 *
 */
+(NSMutableData *)GetDeviceInforWithSequence:(uint8_t)Sequence;

/**
 *
 * @brief         This function is called to disconnect ble by esp32
 * @param sequence :  current sequence
 * @return        data
 *
 */
+(NSMutableData *)DisconnectBLEWithSequence:(uint8_t)Sequence;

/**
 *
 * @brief         This function is called to get wifi list around the device
 * @param sequence :  current sequence
 * @return        data
 *
 */
+(NSMutableData *)GetWifiListWithSequence:(uint8_t)Sequence;

/**
 *
 * @brief         This function is called to connect AP which you send ssid and password before
 * @param sequence :  current sequence
 * @return        data
 *
 */
+(NSMutableData *)ConnectToAPWithSequence:(uint8_t)sequence;

/**
 *
 * @brief         This function is called to disconnect AP which you have connected
 * @param sequence :  current sequence
 * @return        data
 *
 */
+(NSMutableData *)DisconnectFromAPWithSequence:(uint8_t)sequence;

/**
 *
 * @brief         This function is called to set password of STA mode
 * @param sequence  :  current sequence
 * @param Isencrypt :  use encrypt or not
 * @param keydata   :  Secret key
 * @return        data
 *
 */
+(NSMutableData *)SetStationPassword:(NSString *)password  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;

/**
 *
 * @brief         This function is called to set ssid of STA mode
 * @param sequence  :  current sequence
 * @param Isencrypt :  use encrypt or not
 * @param keydata   :  Secret key
 * @return        data
 *
 */
+(NSMutableData *)SetStationSsid:(NSString *)ssid  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;

/**
*
* @brief         This function is called to set ssid of SoftAP
* @param sequence  :  current sequence
* @param Isencrypt :  use encrypt or not
* @param keydata   :  Secret key
* @return        data
*
*/
+(NSMutableData *)SetSoftAPSsid:(NSString *)ssid  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;

/**
 *
 * @brief         This function is called to set password of SoftAP mode
 * @param sequence  :  current sequence
 * @param Isencrypt :  use encrypt or not
 * @param keydata   :  Secret key
 * @return        data
 *
 */
+(NSMutableData *)SetSoftAPPassword:(NSString *)password  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;

/**
 *
 * @brief         This function is called to set Authentication Mode of softAP
 * @param sequence  :  current sequence
 * @param Isencrypt :  use encrypt or not
 * @param keydata   :  Secret key
 * @return        data
 *
 */
+(NSMutableData *)SetAuthenticationforSoftAP:(AuthenticationMode)mode  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;

/**
 *
 * @brief         This function is called to set work Channel of softAP
 * @param sequence  :  current sequence
 * @param Isencrypt :  use encrypt or not
 * @param keydata   :  Secret key
 * @return        data
 *
 */
+(NSMutableData *)SetChannelforSoftAP:(uint8_t)channel  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;

/**
 *
 * @brief         This function is called to set max connection count of softAP
 * @param sequence  :  current sequence
 * @param Isencrypt :  use encrypt or not
 * @param keydata   :  Secret key
 * @return        data
 *
 */
+(NSMutableData *)SetMaxConnectforSoftAP:(uint8_t)max  Sequence:(uint8_t)sequence Encrypt:(BOOL)Isencrypt WithKeyData:(NSData *)keydata;

/**
 *
 * @brief         This function is called to notify security mode to remote device
 * @param sequence  :  current sequence
 * @param security  :  use encrypt or not
 * @param checksum  :  have checksum or not
 * @return        data
 *
 */
+(NSMutableData *)SetESP32ToPhoneSecurityWithSecurity:(BOOL)security CheckSum:(BOOL)checksum Sequence:(uint8_t)sequence;

/**
 *
 * @brief         This function is called to send length of negotiation data
 * @param sequence  :  current sequence
 * @return        data
 *
 */
+(NSMutableData *)SetNegotiatelength:(uint16_t)length Sequence:(uint8_t)sequence;

/**
 *
 * @brief         This function is called to send negotiation data
 * @param sequence  :  current sequence
 * @param flag      :  Fragmentation or not
 * @return        data
 *
 */
+(NSData *)SendNegotiateData:(NSData *)somedata Sequence:(uint8_t)sequence Frag:(BOOL)flag TotalLength:(uint16_t)totallength;

/**
 *
 * @brief         This function is called to String to hexadecimal
 * @param str  :  string
 * @return        hexadecimal data
 *
 */
+(NSData *)convertHexStrToData:(NSString *)str;

/**
 *
 * @brief         This function is called to generate negotiation data
 * @param rsaobject  :  current rsaobject
 * @return        negotiation data
 *
 */
+(NSData *)GenerateNegotiateData:(RSAObject *)rsaobject;

/**
 *
 * @brief         This function is called to send custom data
 * @param sequence  :  current sequence
 * @param flag      :  Whether the encryption
 * @param Isencrypt :  use encrypt or not
 * @param keydata   :  Secret key
 * @return          data
 *
 */
+(NSMutableData *)SendCustomData:(NSData *)custom_data Sequence:(uint8_t)sequence Frag:(BOOL)flag Encrypt:(BOOL)Isencrypt TotalLength:(uint16_t)totallength WithKeyData:(NSData *)keydata;

@end
