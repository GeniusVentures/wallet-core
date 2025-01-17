// Copyright © 2017-2023 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

// mod canonical;
mod keypair;
mod private;
mod public;
mod signature;

pub use keypair::KeyPair;
pub use private::PrivateKey;
pub use public::PublicKey;
pub use signature::{Signature, VerifySignature};

#[cfg(test)]
mod tests {
    use super::*;
    use crate::traits::{KeyPairTrait, SigningKeyTrait, VerifyingKeyTrait};
    use tw_encoding::hex;
    use tw_hash::sha3::keccak256;
    use tw_hash::{H256, H264, H520};
    use tw_misc::traits::{ToBytesVec, ToBytesZeroizing};

    #[test]
    fn test_key_pair() {
        let secret =
            hex::decode("afeefca74d9a325cf1d6b6911d61a65c32afa8e02bd5e78e2e4ac2910bab45f5")
                .unwrap();
        let key_pair = KeyPair::try_from(secret.as_slice()).unwrap();
        assert_eq!(key_pair.private().to_zeroizing_vec().as_slice(), secret);
        assert_eq!(
            key_pair.public().compressed(),
            H264::from("0399c6f51ad6f98c9c583f8e92bb7758ab2ca9a04110c0a1126ec43e5453d196c1")
        );
    }

    #[test]
    fn test_key_pair_sign() {
        let key_pair =
            KeyPair::try_from("afeefca74d9a325cf1d6b6911d61a65c32afa8e02bd5e78e2e4ac2910bab45f5")
                .unwrap();

        let hash_to_sign = keccak256(b"hello");
        let hash_to_sign = H256::try_from(hash_to_sign.as_slice()).unwrap();
        let signature = key_pair.sign(hash_to_sign).unwrap();

        let expected = H520::from("8720a46b5b3963790d94bcc61ad57ca02fd153584315bfa161ed3455e336ba624d68df010ed934b8792c5b6a57ba86c3da31d039f9612b44d1bf054132254de901");
        assert_eq!(signature.to_bytes(), expected);

        let verify_signature = VerifySignature::from(signature);
        assert!(key_pair.verify(verify_signature, hash_to_sign));
    }

    #[test]
    fn test_private_key_from() {
        let hex = "afeefca74d9a325cf1d6b6911d61a65c32afa8e02bd5e78e2e4ac2910bab45f5";
        let expected = hex::decode(hex).unwrap();

        // Test `From<&'static str>`.
        let private = PrivateKey::try_from(hex).unwrap();
        assert_eq!(private.to_zeroizing_vec().as_slice(), expected);

        // Test `From<&'a [u8]>`.
        let private = PrivateKey::try_from(expected.as_slice()).unwrap();
        assert_eq!(private.to_zeroizing_vec().as_slice(), expected);
    }

    #[test]
    fn test_private_key_sign_verify() {
        let secret = "afeefca74d9a325cf1d6b6911d61a65c32afa8e02bd5e78e2e4ac2910bab45f5";
        let private = PrivateKey::try_from(secret).unwrap();
        let public = private.public();

        let hash_to_sign = keccak256(b"hello");
        let hash_to_sign = H256::try_from(hash_to_sign.as_slice()).unwrap();
        let signature = private.sign(hash_to_sign).unwrap();

        let expected = H520::from("8720a46b5b3963790d94bcc61ad57ca02fd153584315bfa161ed3455e336ba624d68df010ed934b8792c5b6a57ba86c3da31d039f9612b44d1bf054132254de901");
        assert_eq!(signature.to_bytes(), expected);

        let verify_signature = VerifySignature::from(signature);
        assert!(public.verify(verify_signature, hash_to_sign));
    }

    #[test]
    fn test_public_key_from() {
        let compressed = "0399c6f51ad6f98c9c583f8e92bb7758ab2ca9a04110c0a1126ec43e5453d196c1";
        let uncompressed = "0499c6f51ad6f98c9c583f8e92bb7758ab2ca9a04110c0a1126ec43e5453d196c166b489a4b7c491e7688e6ebea3a71fc3a1a48d60f98d5ce84c93b65e423fde91";
        let expected_compressed = H264::from(compressed);
        let expected_uncompressed = H520::from(uncompressed);

        // From extended public key.
        let public = PublicKey::try_from(uncompressed).unwrap();
        assert_eq!(public.to_vec(), expected_compressed.into_vec());
        assert_eq!(public.compressed(), expected_compressed);
        assert_eq!(public.uncompressed(), expected_uncompressed);

        // From compressed public key.
        let public = PublicKey::try_from(compressed).unwrap();
        assert_eq!(public.to_vec(), expected_compressed.into_vec());
        assert_eq!(public.compressed(), expected_compressed);
        assert_eq!(public.uncompressed(), expected_uncompressed);
    }

    #[test]
    fn test_verify_invalid() {
        let secret = "afeefca74d9a325cf1d6b6911d61a65c32afa8e02bd5e78e2e4ac2910bab45f5";
        let private = PrivateKey::try_from(secret).unwrap();

        let signature_bytes  = H520::from("375df53b6a4931dcf41e062b1c64288ed4ff3307f862d5c1b1c71964ce3b14c99422d0fdfeb2807e9900a26d491d5e8a874c24f98eec141ed694d7a433a90f0801");
        let verify_sig = VerifySignature::try_from(signature_bytes.as_slice()).unwrap();

        let hash_to_sign = keccak256(b"hello");
        let hash_to_sign = H256::try_from(hash_to_sign.as_slice()).unwrap();

        assert!(!private.public().verify(verify_sig, hash_to_sign));
    }

    #[test]
    fn test_signature() {
        let sign_bytes = H520::from("d93fc9ae934d4f72db91cb149e7e84b50ca83b5a8a7b873b0fdb009546e3af47786bfaf31af61eea6471dbb1bec7d94f73fb90887e4f04d0e9b85676c47ab02a00");
        let sign = Signature::from_bytes(sign_bytes.as_slice()).unwrap();
        assert_eq!(
            sign.r(),
            H256::from("d93fc9ae934d4f72db91cb149e7e84b50ca83b5a8a7b873b0fdb009546e3af47")
        );
        assert_eq!(
            sign.s(),
            H256::from("786bfaf31af61eea6471dbb1bec7d94f73fb90887e4f04d0e9b85676c47ab02a")
        );
        assert_eq!(sign.v(), 0);
        assert_eq!(sign.to_bytes(), sign_bytes);
    }

    #[test]
    fn test_signature_from_invalid_bytes() {
        Signature::from_bytes(b"123").unwrap_err();
    }

    #[test]
    fn test_shared_key_hash() {
        let private = PrivateKey::try_from(
            "9cd3b16e10bd574fed3743d8e0de0b7b4e6c69f3245ab5a168ef010d22bfefa0",
        )
        .unwrap();
        let public = PublicKey::try_from(
            "02a18a98316b5f52596e75bfa5ca9fa9912edd0c989b86b73d41bb64c9c6adb992",
        )
        .unwrap();
        let actual = private.shared_key_hash(&public);
        let expected =
            H256::from("ef2cf705af8714b35c0855030f358f2bee356ff3579cea2607b2025d80133c3a");
        assert_eq!(actual, expected);
    }
}
