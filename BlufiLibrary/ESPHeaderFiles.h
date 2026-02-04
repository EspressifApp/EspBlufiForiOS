//
//  ESPHeaderFiles.h
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/24.
//  Copyright © 2020 espressif. All rights reserved.
//

#ifndef ESPHeaderFiles_h
#define ESPHeaderFiles_h

// Define OPENSSL_API_COMPAT before including OpenSSL headers to ensure deprecated functions are declared
// This prevents DEPRECATEDIN_1_1_0 from expanding to empty, which causes compilation errors
#ifndef OPENSSL_API_COMPAT
#define OPENSSL_API_COMPAT 0x10000000L
#endif

// Include opensslconf.h first to ensure BN_ULONG and other types are defined
#import <openssl/opensslconf.h>
#import <openssl/dh.h>
#import <CommonCrypto/CommonCrypto.h>
#import <openssl/rsa.h>
#import <openssl/pem.h>
#import <openssl/bn.h>

#endif /* ESPHeaderFiles_h */
