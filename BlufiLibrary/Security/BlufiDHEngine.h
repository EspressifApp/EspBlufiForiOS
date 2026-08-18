//
//  BlufiDHEngine.h
//  EspBlufi
//
//  Local, dependency-free implementation of the finite-field Diffie-Hellman
//  big-integer operations used by the Blufi negotiation (1024-bit and
//  3072-bit MODP groups, generator g = 2). It replaces OpenSSL's DH/BN usage.
//
//  All byte buffers are big-endian (most-significant byte first), matching the
//  on-wire Blufi protocol and the previous OpenSSL BN_bin2bn/BN_bn2bin usage.
//

#ifndef BlufiDHEngine_h
#define BlufiDHEngine_h

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Largest supported modulus: 3072 bits = 384 bytes.
#define BLUFI_DH_MAX_BYTES 384

/// Generate a fresh DH key pair for modulus `p`.
/// - p / p_len: prime modulus, big-endian bytes (128 or 384).
/// - priv_out / pub_out: output buffers, each at least p_len bytes.
///   Both are written big-endian, left-padded with zeros to exactly p_len bytes.
/// Returns 0 on success, non-zero on invalid input.
int blufi_dh_generate_key(const uint8_t *p, size_t p_len,
                          uint8_t *priv_out, uint8_t *pub_out);

/// Compute the public key pub = g^priv mod p (g = 2) for a given private key.
/// - priv / priv_len: private key, big-endian bytes.
/// - pub_out: output buffer, at least p_len bytes (left-padded to p_len bytes).
/// Returns 0 on success, non-zero on invalid input.
int blufi_dh_compute_public(const uint8_t *p, size_t p_len,
                            const uint8_t *priv, size_t priv_len,
                            uint8_t *pub_out);

/// Compute the shared secret secret = peer_pub^priv mod p.
/// - priv / priv_len: local private key, big-endian bytes.
/// - peer_pub / peer_pub_len: peer public key, big-endian bytes.
/// - out: output buffer, at least p_len bytes.
/// Returns the number of bytes written (leading zero bytes stripped), or 0 on
/// error. The output is big-endian.
size_t blufi_dh_compute_secret(const uint8_t *p, size_t p_len,
                               const uint8_t *priv, size_t priv_len,
                               const uint8_t *peer_pub, size_t peer_pub_len,
                               uint8_t *out);

#ifdef __cplusplus
}
#endif

#endif /* BlufiDHEngine_h */
