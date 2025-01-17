// Copyright © 2017-2023 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

use tw_encoding::hex;
use tw_hash::sha2::sha256;
use tw_hash::sha3::keccak256;
use tw_keypair::ffi::pubkey::{
    tw_public_key_create_with_data, tw_public_key_delete, tw_public_key_verify, TWPublicKey,
};
use tw_keypair::tw::PublicKeyType;
use tw_memory::ffi::c_byte_array::CByteArray;

struct TWPublicKeyHelper {
    ptr: *mut TWPublicKey,
}

impl TWPublicKeyHelper {
    fn with_bytes<T: Into<Vec<u8>>>(bytes: T, ty: PublicKeyType) -> TWPublicKeyHelper {
        let public_key_raw = CByteArray::from(bytes.into());
        let ptr = unsafe {
            tw_public_key_create_with_data(public_key_raw.data(), public_key_raw.size(), ty as u32)
        };
        TWPublicKeyHelper { ptr }
    }

    fn with_hex(hex: &str, ty: PublicKeyType) -> TWPublicKeyHelper {
        let priv_key_data = hex::decode(hex).unwrap();
        TWPublicKeyHelper::with_bytes(priv_key_data, ty)
    }
}

impl Drop for TWPublicKeyHelper {
    fn drop(&mut self) {
        if self.ptr.is_null() {
            return;
        }
        unsafe { tw_public_key_delete(self.ptr) };
    }
}

fn test_verify(ty: PublicKeyType, public: &str, msg: &str, sign: &str) {
    let tw_public = TWPublicKeyHelper::with_hex(public, ty);
    assert!(!tw_public.ptr.is_null());

    let signature_bytes = hex::decode(sign).unwrap();
    let signature_raw = CByteArray::from(signature_bytes);
    let msg = hex::decode(msg).unwrap();
    let msg_raw = CByteArray::from(msg);

    let valid = unsafe {
        tw_public_key_verify(
            tw_public.ptr,
            signature_raw.data(),
            signature_raw.size(),
            msg_raw.data(),
            msg_raw.size(),
        )
    };
    assert!(valid);
}

#[test]
fn test_tw_public_key_create_by_type() {
    let tw_public = TWPublicKeyHelper::with_hex(
        "02a18a98316b5f52596e75bfa5ca9fa9912edd0c989b86b73d41bb64c9c6adb992",
        PublicKeyType::Secp256k1,
    );
    assert!(!tw_public.ptr.is_null());

    // Compressed pubkey with '03' prefix.
    let tw_public = TWPublicKeyHelper::with_hex(
        "0399c6f51ad6f98c9c583f8e92bb7758ab2ca9a04110c0a1126ec43e5453d196c1",
        PublicKeyType::Secp256k1,
    );
    assert!(!tw_public.ptr.is_null());

    let tw_public = TWPublicKeyHelper::with_hex(
        "0499c6f51ad6f98c9c583f8e92bb7758ab2ca9a04110c0a1126ec43e5453d196c166b489a4b7c491e7688e6ebea3a71fc3a1a48d60f98d5ce84c93b65e423fde91",
        PublicKeyType::Secp256k1Extended,
    );
    assert!(!tw_public.ptr.is_null());

    // Pass an extended pubkey, but Secp256k1 type.
    let tw_public = TWPublicKeyHelper::with_hex(
        "0499c6f51ad6f98c9c583f8e92bb7758ab2ca9a04110c0a1126ec43e5453d196c166b489a4b7c491e7688e6ebea3a71fc3a1a48d60f98d5ce84c93b65e423fde91",
        PublicKeyType::Secp256k1,
    );
    assert!(tw_public.ptr.is_null());

    // Pass a compressed pubkey, but Secp256k1Extended type.
    let tw_public = TWPublicKeyHelper::with_hex(
        "02a18a98316b5f52596e75bfa5ca9fa9912edd0c989b86b73d41bb64c9c6adb992",
        PublicKeyType::Secp256k1Extended,
    );
    assert!(tw_public.ptr.is_null());
}

#[test]
fn test_tw_public_key_delete_null() {
    unsafe { tw_public_key_delete(std::ptr::null_mut()) };
}

#[test]
fn test_tw_public_key_verify_secp256k1() {
    let public = "0399c6f51ad6f98c9c583f8e92bb7758ab2ca9a04110c0a1126ec43e5453d196c1";
    let msg = hex::encode(keccak256(b"hello").as_slice(), false);
    let sign = "8720a46b5b3963790d94bcc61ad57ca02fd153584315bfa161ed3455e336ba624d68df010ed934b8792c5b6a57ba86c3da31d039f9612b44d1bf054132254de901";
    test_verify(PublicKeyType::Secp256k1, public, &msg, sign);
}

#[test]
fn test_tw_public_key_verify_ed25519() {
    let public = "4870d56d074c50e891506d78faa4fb69ca039cc5f131eb491e166b975880e867";
    let msg = hex::encode(sha256(b"Hello").as_slice(), false);
    let sign = "42848abf2641a731e18b8a1fb80eff341a5acebdc56faeccdcbadb960aef775192842fccec344679446daa4d02d264259c8f9aa364164ebe0ebea218581e2e03";
    test_verify(PublicKeyType::Ed25519, public, &msg, sign);
}

#[test]
fn test_tw_public_key_verify_ed25519_blake2b() {
    let public = "b689ab808542e13f3d2ec56fe1efe43a1660dcadc73ce489fde7df98dd8ce5d9";
    let msg = hex::encode(sha256(b"Hello").as_slice(), false);
    let sign = "5c1473944cd0234ebc5a91b2966b9e707a33b936dadd149417a2e53b6b3fc97bef17b767b1690708c74d7b4c8fe48703fd44a6ef59d4cc5b9f88ba992db0a003";
    test_verify(PublicKeyType::Ed25519Blake2b, public, &msg, sign);
}

#[test]
fn test_tw_public_key_verify_ed25519_extended_cardano() {
    let public = "57fd54be7b38bb8952782c2f59aa276928a4dcbb66c8c62ce44f9d623ecd5a03bf36a8fa9f5e11eb7a852c41e185e3969d518e66e6893c81d3fc7227009952d4\
    06465638ee0e1ca1a9f34d940a0c8c48bbaaa0db124107e4c1b12b872a67511fed7f28be986cbe06819165f2ee41b403678a098961013cf4a2f3e9ea61fb6c1a";
    let msg = hex::encode(keccak256(b"hello").as_slice(), false);
    let sign = "375df53b6a4931dcf41e062b1c64288ed4ff3307f862d5c1b1c71964ce3b14c99422d0fdfeb2807e9900a26d491d5e8a874c24f98eec141ed694d7a433a90f08";
    test_verify(PublicKeyType::Ed25519ExtendedCardano, public, &msg, sign);
}
