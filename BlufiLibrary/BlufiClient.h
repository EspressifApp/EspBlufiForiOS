//
//  BlufiClient.h
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BlufiConstants.h"
#import "BlufiStatusResponse.h"
#import "BlufiScanResponse.h"
#import "BlufiVersionResponse.h"
#import "BlufiConfigureParams.h"

NS_ASSUME_NONNULL_BEGIN

#define BLUFI_VERSION @"2.2.0"

@protocol BlufiDelegate;

@interface BlufiClient : NSObject

/*!
 *  @property delegate
 *
 *  @discussion The delegate object that will receive Blufi events.
 */
@property(weak, nonatomic, nullable)id<BlufiDelegate> blufiDelegate;

/*!
 *  @property delegate
 *
 *  @discussion The delegate object that will receive central events.
*/
@property(weak, nonatomic, nullable)id<CBCentralManagerDelegate> centralManagerDelete;

/*!
 *  @property peripheralDelegate
 *
 *  @discussion The delegate object that will receive peripheral events.
 */
@property(weak, nonatomic, nullable)id<CBPeripheralDelegate> peripheralDelegate;

/*!
 *  @property peripheralDelegate
 *
 *  @discussion The maximum length of each Blufi packet, the excess part will be subcontracted.
 */
@property(assign, nonatomic)NSInteger postPackageLengthLimit;

/*!
 * @method connect:
 *
 * @param identifier CBPeripheral's identifier
 *
 * @discussion Establish a BLE connection with CBPeripheral
 */
- (void)connect:(NSString *)identifier;

/*!
 * @method close
 *
 * @discussion Close the client
 */
- (void)close;

/*!
 * @method negotiateSecurity
 *
 * @discussion Negotiate security with device.
 *             The result will be notified in <link>blufi:didNegotiateSecurity:</link>
 */
- (void)negotiateSecurity;

/*!
 * @method requestCloseConnection
 *
 * @discussion Request device to disconnect the BLE connection
 */
- (void)requestCloseConnection;

/*!
 * @method requestDeviceVersion
 *
 * @discussion Request to get device version.
 *             The result will notified in <link>blufi:didReceiveDeviceVersionResponse:status:</link>
 */
- (void)requestDeviceVersion;

/*!
 * @method requestDeviceStatus
 *
 * @discussion Request to get device current status.
 *             The result will be notified in <link>blufi:didReceiveDeviceStatusResponse:status:</link>
 */
- (void)requestDeviceStatus;

/*!
 * @method requestDeviceScan
 *
 * @discussion Request to get wifi list that the device scanned.
 *             The wifi list will be notified in <link>blufi:didReceiveDeviceScanResponse:status:</link>
 */
- (void)requestDeviceScan;

/*!
 * @method configure:
 *
 * @discussion Configure the device to a station or soft AP.
 *             The posted result will be notified in <link>blufi:didPostConfigureParams:</link>
 */
- (void)configure:(BlufiConfigureParams *)params;

/*!
 * @method postCustomData:
 *
 * @discussion Request to post custom data to device.
 *             The posted result will be notified in <link>blufi:didPostCustomData:status:</link>
 */
- (void)postCustomData:(NSData *)data;

@end

typedef enum {
    StatusSuccess = 0,
    StatusFailed = 100,
    StatusInvalidRequest,
    StatusWriteFailed,
    StatusInvalidData,
    StatusBLEStateDisable,
    StatusException,
} BlufiStatusCode;

// Blufi Callback
@protocol BlufiDelegate <NSObject>

@optional

/*!
 * @method blufi:gettPrepared:service:writeChar:notifyChar:
 *
 * @param client BlufiClient
 * @param status see <code>BlufiStatusCode</code>
 * @param service nil if discover Blufi service failed
 * @param writeChar nil if discover Blufi write characteristic failed
 * @param notifyChar nil if discover Blufi notify characteristic failed
 *
 * @discussion Invoked after client set notifyChar notification enable. User can post BluFi packet now.
 */
- (void)blufi:(BlufiClient *)client gattPrepared:(BlufiStatusCode)status service:(nullable CBService *)service writeChar:(nullable CBCharacteristic *)writeChar notifyChar:(nullable CBCharacteristic *)notifyChar;

/*!
 * @method blufi:gattNotification:packageType:subType:
 *
 * @param client BlufiClient
 * @param data Blufi data
 * @param pkgType Blufi package type
 * @param subType Blufi subtype
 *
 * @return true if the delegate consumed the notification, false otherwise.
 *
 * @discussion Invoked when receive Gatt notification
 */
- (BOOL)blufi:(BlufiClient *)client gattNotification:(NSData *)data packageType:(PackageType)pkgType subType:(SubType)subType;

/*!
 * @method blufi:didReceiveError:
 *
 * @param client BlufiClient
 * @param errCode error code
 *
 * @discussion Invoked when received error code from device
 */
- (void)blufi:(BlufiClient *)client didReceiveError:(NSInteger)errCode;

/*!
 * @method blufi:didNegotiateSecurity:
 *
 * @param client BlufiClient
 * @param status see  <code>BlufiStatusCode</code>, StatusSuccess means negotiate security success.
 *
 * @discussion Invoked when negotiate security over with device
 */
- (void)blufi:(BlufiClient *)client didNegotiateSecurity:(BlufiStatusCode)status;

/*!
 * @method blufi:didPostConfigureParams:
 *
 * @param client BlufiClient
 * @param status see  <code>BlufiStatusCode</code>, StatusSuccess means post data success.
 *
 * @discussion Invoked when post config data over
 */
- (void)blufi:(BlufiClient *)client didPostConfigureParams:(BlufiStatusCode)status;

/*!
 * @method blufi:didReceiveDeviceVersionResponse:status:
 *
 * @param client BlufiClient
 * @param response <code>BlufiVersionResponse</code>
 * @param status see  <code>BlufiStatusCode</code>, StatusSuccess means response is valid.
 *
 * @discussion invoked when received device version
 */
- (void)blufi:(BlufiClient *)client didReceiveDeviceVersionResponse:(nullable BlufiVersionResponse *)response status:(BlufiStatusCode)status;

/*!
 * @method blufi:didReceiveDeviceStatusResponse:status:
 *
 * @param client BlufiClient
 * @param response <code>BlufiStatusResponse</code>
 * @param status see  <code>BlufiStatusCode</code>, StatusSuccess means response is valid.
 *
 * @discussion Invoked when received device status.
 */
- (void)blufi:(BlufiClient *)client didReceiveDeviceStatusResponse:(nullable BlufiStatusResponse *)response status:(BlufiStatusCode)status;

/*!
 * @method blufi:didReceiveDeviceScanResponse:status:
 *
 * @param client BlufiClient
 * @param scanResults scan result array
 * @param status see  <code>BlufiStatusCode</code>, StatusSuccess means response is valid.
 *
 * @discussion Invoked when received device scan results
 */
- (void)blufi:(BlufiClient *)client didReceiveDeviceScanResponse:(nullable NSArray<BlufiScanResponse *> *)scanResults status:(BlufiStatusCode)status;


/*!
 * @method blufi:didPostCustomData:status:
 *
 * @param client BlufiClient
 * @param data posted
 * @param status see  <code>BlufiStatusCode</code>, StatusSuccess means post data success
 *
 * @discussion Invokded when post custom data success
 */
- (void)blufi:(BlufiClient *)client didPostCustomData:(NSData *)data status:(BlufiStatusCode)status;

/*!
 * @method blufi:didReceiveCustomData:status:
 *
 *@param client BlufiClient
 *@param data received
 *@param status see  <code>BlufiStatusCode</code>, StatusSuccess means receive data success
 *
 */
- (void)blufi:(BlufiClient *)client didReceiveCustomData:(NSData *)data status:(BlufiStatusCode)status;

@end

NS_ASSUME_NONNULL_END
