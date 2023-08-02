// Copyright © 2017-2023 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

#pragma once

#include "Data.h"
#include "rust/bindgen/WalletCoreRSBindgen.h"
#include "rust/Wrapper.h"

#include <cassert>

namespace TW::Base32 {

/// Decode Base32 string, return bytes as Data
/// alphabet: Optional alphabet, if missing, default ALPHABET_RFC4648
inline bool decode(const std::string& encoded_in, Data& decoded_out, const char* alphabet_in = nullptr) {
    size_t inLen = encoded_in.size();
    // obtain output length first
    size_t outLen = base32_decoded_length(inLen);
#ifdef _MSC_VER
    uint8_t *buf = (uint8_t *)_alloca(outLen);
#else
    uint8_t buf[outLen];
#endif
    if (alphabet_in == nullptr) {
        alphabet_in = BASE32_ALPHABET_RFC4648;
    }
    Rust::CByteArrayResultWrapper res = Rust::decode_base32(encoded_in.c_str(), alphabet_in, false);
    if (res.isOk()) {
        decoded_out = res.unwrap().data;
        return true;
    }
    return false;
}


/// Encode bytes in Data to Base32 string
/// alphabet: Optional alphabet, if missing, default ALPHABET_RFC4648
inline std::string encode(const Data& val, const char* alphabet = nullptr) {
    size_t inLen = val.size();
    // obtain output length first, reserve for terminator
    size_t outLen = base32_encoded_length(inLen) + 1;
#ifdef _MSC_VER
    char *buf = (char *)_alloca(outLen);
#else
    char buf[outLen];
#endif
    if (alphabet == nullptr) {
        alphabet = BASE32_ALPHABET_RFC4648;
    }
    // perform the base32 encode
    char* retval = base32_encode(val.data(), inLen, buf, outLen, alphabet);
    if (retval == nullptr) {
        // return empty string if failed
        return std::string();
    }
    std::string encoded_str(res.result);
    Rust::free_string(res.result);
    return encoded_str;
}

} // namespace TW::Base32
