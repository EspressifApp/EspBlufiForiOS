//
//  BlufiConstants.h
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlufiConstants : NSObject

#define UUID_SERVICE      @"FFFF"
#define UUID_WRITE_CHAR   @"FF01"
#define UUID_NOTIFY_CHAR  @"FF02"

typedef enum {
    OpModeNull = 0,
    OpModeSta,
    OpModeSoftAP,
    OpModeStaSoftAP,
} OpMode;

typedef enum {
    SoftAPSecurityOpen = 0,
    SoftAPSecurityWEP,
    SoftAPSecurityWPA,
    SoftAPSecurityWPA2,
    SoftAPSecurityWPAWPA2,
    SoftAPSecurityUnknown,
} SoftAPSecurity;

typedef enum {
    DataOutput = 0,
    DataInput,
} DataDirection;

typedef enum {
    PackageCtrl = 0,
    PackageData
} PackageType;

enum {
    CtrlSubTypeAck = 0,
    CtrlSubTypeSetSecurityMode,
    CtrlSubTypeSetOpMode,
    CtrlSubTypeConnectWiFi,
    CtrlSubTypeDisconnectWiFi,
    CtrlSubTypeGetWiFiStatus,
    CtrlSubTypeDeauthenticate,
    CtrlSubTypeGetVersion,
    CtrlSubTypeCloseConnection,
    CtrlSubTypeGetWiFiList,
};
enum {
    DataSubTypeNeg = 0,
    DataSubTypeStaBssid,
    DataSubTypeStaSsid,
    DataSubTypeStaPassword,
    DataSubTypeSoftAPSsid,
    DataSubTypeSoftAPPassword,
    DataSubTypeSoftAPMaxConnection,
    DataSubTypeSoftAPAuthMode,
    DataSubTypeSoftAPChannel,
    DataSubTypeUserName,
    DataSubTypeCACertification,
    DataSubTypeClentCertification,
    DataSubTypeServerCertification,
    DataSubTypeClientPrivateKey,
    DataSubTypeServerPrivateKey,
    DataSubTypeWiFiConnectionState,
    DataSubTypeVersion,
    DataSubTypeWiFiList,
    DataSubTypeError,
    DataSubTypeCustomData
};
typedef uint32_t SubType;

@end

NS_ASSUME_NONNULL_END
