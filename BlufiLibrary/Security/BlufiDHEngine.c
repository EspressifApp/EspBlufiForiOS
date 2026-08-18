//
//  BlufiDHEngine.c
//  EspBlufi
//
//  Local, dependency-free Diffie-Hellman big-integer implementation.
//
//  Representation: little-endian arrays of 32-bit words (word[0] is the least
//  significant word). Modulus bit length is always an exact multiple of 32
//  (1024 or 3072 bits), which allows a word-aligned Barrett reduction.
//  Modular exponentiation uses a constant-time Montgomery powering ladder.
//

#include "BlufiDHEngine.h"
#include <string.h>
#include <stdlib.h>

typedef uint32_t word_t;
typedef uint64_t dword_t;

#define WORD_BITS 32
#define MAX_WORDS (BLUFI_DH_MAX_BYTES / 4)   /* 96 words = 3072 bits */

/* ------------------------------------------------------------------ */
/* Basic little-endian word-array helpers                              */
/* ------------------------------------------------------------------ */

/* compare a and b (n words each): -1 / 0 / +1 */
static int bn_cmp(const word_t *a, const word_t *b, int n) {
    for (int i = n - 1; i >= 0; i--) {
        if (a[i] < b[i]) return -1;
        if (a[i] > b[i]) return 1;
    }
    return 0;
}

/* a >= b ? (a has n+1 words, b has n words) */
static int bn_ge(const word_t *a, const word_t *b, int n) {
    if (a[n] != 0) return 1;
    for (int i = n - 1; i >= 0; i--) {
        if (a[i] > b[i]) return 1;
        if (a[i] < b[i]) return 0;
    }
    return 1;
}

/* a -= b (a has n+1 words, b has n words), requires a >= b */
static void bn_sub(word_t *a, const word_t *b, int n) {
    dword_t borrow = 0;
    for (int i = 0; i < n; i++) {
        dword_t sub = (dword_t)b[i] + borrow;
        dword_t da = a[i];
        if (da < sub) {
            a[i] = (word_t)(da + ((dword_t)1 << WORD_BITS) - sub);
            borrow = 1;
        } else {
            a[i] = (word_t)(da - sub);
            borrow = 0;
        }
    }
    if (borrow) a[n] -= 1;
}

/* r = a * b; a has na words, b has nb words; r has na+nb words (zeroed first) */
static void bn_mul(word_t *r, const word_t *a, int na, const word_t *b, int nb) {
    for (int i = 0; i < na + nb; i++) r[i] = 0;
    for (int i = 0; i < na; i++) {
        dword_t carry = 0;
        dword_t ai = a[i];
        for (int j = 0; j < nb; j++) {
            dword_t cur = ai * (dword_t)b[j] + r[i + j] + carry;
            r[i + j] = (word_t)cur;
            carry = cur >> WORD_BITS;
        }
        r[i + nb] = (word_t)carry;
    }
}

/* Parse big-endian bytes into n little-endian words (high words zero-padded). */
static void bn_from_be(word_t *out, const uint8_t *be, size_t len, int n) {
    memset(out, 0, (size_t)n * sizeof(word_t));
    for (size_t i = 0; i < len; i++) {
        size_t byte_index = len - 1 - i;   /* be[0] is most significant */
        out[i / 4] |= (word_t)be[byte_index] << (8 * (i % 4));
    }
}

/* Serialize n little-endian words to big-endian bytes (exactly 4*n bytes). */
static void bn_to_be(uint8_t *out, const word_t *a, int n) {
    for (int i = 0; i < n; i++) {
        word_t w = a[i];
        out[(size_t)(n - 1 - i) * 4 + 0] = (uint8_t)(w >> 24);
        out[(size_t)(n - 1 - i) * 4 + 1] = (uint8_t)(w >> 16);
        out[(size_t)(n - 1 - i) * 4 + 2] = (uint8_t)(w >> 8);
        out[(size_t)(n - 1 - i) * 4 + 3] = (uint8_t)(w);
    }
}

/* ------------------------------------------------------------------ */
/* Barrett reduction (HAC 14.42, word-aligned; modulus bit length = 32n) */
/* ------------------------------------------------------------------ */

/* mu = floor(2^(64n) / m), written to n+1 words. */
static void barrett_mu(word_t *mu, const word_t *m, int n) {
    word_t rem[MAX_WORDS + 1];
    memset(rem, 0, sizeof(rem));
    memset(mu, 0, (size_t)(n + 1) * sizeof(word_t));

    int total_bits = 64 * n;                 /* dividend = 2^(64n) */
    for (int bit = total_bits; bit >= 0; bit--) {
        /* rem <<= 1 */
        dword_t carry = 0;
        for (int i = 0; i <= n; i++) {
            dword_t cur = ((dword_t)rem[i] << 1) | carry;
            rem[i] = (word_t)cur;
            carry = cur >> WORD_BITS;
        }
        if (bit == total_bits) rem[0] |= 1;  /* the single set bit of 2^(64n) */

        if (bn_ge(rem, m, n)) {
            bn_sub(rem, m, n);
            if (bit / WORD_BITS <= n) {       /* quotient fits n+1 words */
                mu[bit / WORD_BITS] |= (word_t)1 << (bit % WORD_BITS);
            }
        }
    }
}

/* r = x mod m; x has 2n words; mu = floor(2^(64n)/m) has n+1 words. */
static void barrett_reduce(word_t *r, const word_t *x, const word_t *m,
                           const word_t *mu, int n) {
    word_t q1[MAX_WORDS + 1];
    word_t q2[2 * MAX_WORDS + 2];
    word_t q3[MAX_WORDS + 1];
    word_t tmp[2 * MAX_WORDS + 2];
    word_t rv[MAX_WORDS + 1];

    /* q1 = floor(x / 2^(32(n-1))) = high n+1 words of x */
    for (int i = 0; i <= n; i++) q1[i] = x[n - 1 + i];

    /* q2 = q1 * mu (2n+2 words) */
    bn_mul(q2, q1, n + 1, mu, n + 1);

    /* q3 = floor(q2 / 2^(32(n+1))) = high n+1 words of q2 */
    for (int i = 0; i <= n; i++) q3[i] = q2[n + 1 + i];

    /* r2 = (q3 * m) mod 2^(32(n+1)) = low n+1 words of q3*m */
    bn_mul(tmp, q3, n + 1, m, n);

    /* r = (r1 - r2) mod 2^(32(n+1)), where r1 = low n+1 words of x.
       x has 2n words so x[n .. 2n-1] contribute to r1's high word via q1,
       but r1 = x mod 2^(32(n+1)) only needs x[0..n] (words 0..n), and x[n]=0. */
    dword_t borrow = 0;
    for (int i = 0; i <= n; i++) {
        dword_t sub = (dword_t)tmp[i] + borrow;
        dword_t da = x[i];                    /* x[i] == 0 for i == n (2n-word x) */
        if (da < sub) {
            rv[i] = (word_t)(da + ((dword_t)1 << WORD_BITS) - sub);
            borrow = 1;
        } else {
            rv[i] = (word_t)(da - sub);
            borrow = 0;
        }
    }

    /* Correct: result is < 2m, so at most two subtractions. */
    while (bn_ge(rv, m, n)) bn_sub(rv, m, n);

    for (int i = 0; i < n; i++) r[i] = rv[i];
}

/* r = a * b mod m */
static void modmul(word_t *r, const word_t *a, const word_t *b,
                   const word_t *m, const word_t *mu, int n) {
    word_t x[2 * MAX_WORDS];
    bn_mul(x, a, n, b, n);
    barrett_reduce(r, x, m, mu, n);
}

/* r = base^exp mod m, constant-time Montgomery powering ladder.
   exp has n words; the exponent bit length is fixed at 32n. */
static void modexp(word_t *r, const word_t *base, const word_t *exp,
                   const word_t *m, const word_t *mu, int n) {
    word_t r0[MAX_WORDS];
    word_t r1[MAX_WORDS];
    word_t t[MAX_WORDS];

    memset(r0, 0, (size_t)n * sizeof(word_t));
    r0[0] = 1;                                   /* r0 = 1 */
    memcpy(r1, base, (size_t)n * sizeof(word_t)); /* r1 = base */

    int bits = 32 * n;
    for (int i = bits - 1; i >= 0; i--) {
        word_t bit = (exp[i / WORD_BITS] >> (i % WORD_BITS)) & 1;
        word_t mask = (word_t)0 - bit;           /* 0 or 0xFFFFFFFF */

        /* constant-time conditional swap(r0, r1) */
        for (int j = 0; j < n; j++) {
            word_t x = (r0[j] ^ r1[j]) & mask;
            r0[j] ^= x;
            r1[j] ^= x;
        }

        modmul(t, r0, r1, m, mu, n); memcpy(r1, t, (size_t)n * sizeof(word_t)); /* r1 = r0*r1 */
        modmul(t, r0, r0, m, mu, n); memcpy(r0, t, (size_t)n * sizeof(word_t)); /* r0 = r0^2 */

        for (int j = 0; j < n; j++) {
            word_t x = (r0[j] ^ r1[j]) & mask;
            r0[j] ^= x;
            r1[j] ^= x;
        }
    }
    memcpy(r, r0, (size_t)n * sizeof(word_t));
}

/* ------------------------------------------------------------------ */
/* Public API                                                          */
/* ------------------------------------------------------------------ */

static int words_of(size_t p_len) {
    return (int)(p_len / 4);
}

int blufi_dh_compute_public(const uint8_t *p, size_t p_len,
                            const uint8_t *priv, size_t priv_len,
                            uint8_t *pub_out) {
    if (!p || p_len == 0 || p_len > BLUFI_DH_MAX_BYTES || p_len % 4 != 0) return -1;
    if (!priv || priv_len == 0 || priv_len > p_len) return -1;
    if (!pub_out) return -1;

    int n = words_of(p_len);
    word_t m[MAX_WORDS], mu[MAX_WORDS + 1];
    word_t priv_w[MAX_WORDS], base[MAX_WORDS], pub[MAX_WORDS];

    bn_from_be(m, p, p_len, n);
    barrett_mu(mu, m, n);
    bn_from_be(priv_w, priv, priv_len, n);

    memset(base, 0, (size_t)n * sizeof(word_t));
    base[0] = 2;                                 /* generator g = 2 */

    modexp(pub, base, priv_w, m, mu, n);
    bn_to_be(pub_out, pub, n);
    return 0;
}

size_t blufi_dh_compute_secret(const uint8_t *p, size_t p_len,
                               const uint8_t *priv, size_t priv_len,
                               const uint8_t *peer_pub, size_t peer_pub_len,
                               uint8_t *out) {
    if (!p || p_len == 0 || p_len > BLUFI_DH_MAX_BYTES || p_len % 4 != 0) return 0;
    if (!priv || priv_len == 0 || priv_len > p_len) return 0;
    if (!peer_pub || peer_pub_len == 0 || peer_pub_len > p_len) return 0;
    if (!out) return 0;

    int n = words_of(p_len);
    word_t m[MAX_WORDS], mu[MAX_WORDS + 1];
    word_t priv_w[MAX_WORDS], peer[MAX_WORDS], secret[MAX_WORDS];
    uint8_t be[BLUFI_DH_MAX_BYTES];

    bn_from_be(m, p, p_len, n);
    barrett_mu(mu, m, n);
    bn_from_be(priv_w, priv, priv_len, n);
    bn_from_be(peer, peer_pub, peer_pub_len, n);

    modexp(secret, peer, priv_w, m, mu, n);
    bn_to_be(be, secret, n);

    /* Strip leading zero bytes (matches OpenSSL DH_compute_key / mbedTLS). */
    size_t off = 0;
    while (off < p_len && be[off] == 0) off++;
    size_t len = p_len - off;
    memcpy(out, be + off, len);
    return len;
}

int blufi_dh_generate_key(const uint8_t *p, size_t p_len,
                          uint8_t *priv_out, uint8_t *pub_out) {
    if (!p || p_len == 0 || p_len > BLUFI_DH_MAX_BYTES || p_len % 4 != 0) return -1;
    if (!priv_out || !pub_out) return -1;

    int n = words_of(p_len);
    word_t m[MAX_WORDS], m_minus_1[MAX_WORDS];
    uint8_t buf[BLUFI_DH_MAX_BYTES];

    bn_from_be(m, p, p_len, n);
    /* m_minus_1 = p - 1 */
    memcpy(m_minus_1, m, (size_t)n * sizeof(word_t));
    dword_t borrow = 1;
    for (int i = 0; i < n && borrow; i++) {
        dword_t da = m_minus_1[i];
        if (da >= borrow) { m_minus_1[i] = (word_t)(da - borrow); borrow = 0; }
        else { m_minus_1[i] = (word_t)(da + ((dword_t)1 << WORD_BITS) - borrow); borrow = 1; }
    }

    /* Rejection-sample a private key: 2 <= priv <= p-2, top bit set to keep a
       fixed bit length (mirrors OpenSSL DH_generate_key's BN_rand TOP_ONE). */
    word_t priv_w[MAX_WORDS];
    int ok = 0;
    for (int attempt = 0; attempt < 64 && !ok; attempt++) {
        arc4random_buf(buf, p_len);
        bn_from_be(priv_w, buf, p_len, n);
        priv_w[n - 1] |= (word_t)1 << 31;        /* force top bit to 1 */

        /* check priv >= 2 */
        int ge2 = 0;
        for (int i = n - 1; i >= 1; i--) { if (priv_w[i]) { ge2 = 1; break; } }
        if (!ge2) ge2 = (priv_w[0] >= 2) ? 1 : 0;

        /* check priv < p - 1 */
        int lt = (bn_cmp(priv_w, m_minus_1, n) < 0) ? 1 : 0;

        if (ge2 && lt) ok = 1;
    }
    if (!ok) return -2;

    bn_to_be(priv_out, priv_w, n);

    /* pub = g^priv mod p (g = 2) */
    return blufi_dh_compute_public(p, p_len, priv_out, p_len, pub_out);
}
