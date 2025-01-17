// Copyright © 2017-2023 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

//! `tw_keypair` crate defines the keypairs, private and public keys that are used to sign messages,
//! verify signatures and more.
//!
//! # Usage - Generic TW solution
//!
//! If you plan to work with different curves in the same app by using the same private key,
//! consider using [`tw::PrivateKey`], [`tw::PublicKey`], [`tw::KeyPair`] (TODO).
//!
//! ```rust,ignore
//! use tw_keypair::{tw::PrivateKey, Curve};
//!
//! let private = PrivateKey::try_from(YOUR_SECRET_BYTES).unwrap();
//!
//! // Sign an ETH transaction hash with the `private` key.
//! let eth_signature = private.sign(ETH_TX_HASH, Curve::Secp256k1).unwrap();
//! assert_eq(eth_signature.len(), 65);
//!
//! // Sign a SUI transaction hash with the same `private` key, but different `curve`.
//! let sui_signature = private.sign(SUI_TX_HASH, Curve::Ed25519).unwrap();
//! ```
//!
//! # Usage - Specific curve
//!
//! If you plan to work with only one curve, consider using a specific curve implementation.
//! For example, if you work with ETH, therefore  the`secp256k1` curve:
//!
//! ```rust,ignore
//! use tw_keypair::secp256k1::KeyPair;
//!
//! let keypair = KeyPair::try_from(YOUR_SECRET_BYTES).unwrap();
//!
//! // Sign an ETH transaction hash.
//! // [`tw_keypair::secp256k1::KeyPair::sign`] returns a [`tw_keypair::secp256k1::Signature`].
//! let eth_signature = private.sign(ETH_TX_HASH, Curve::Secp256k1).unwrap();
//!
//! assert_eq(eth_signature.r, H256::from(EXPECTED_R_HEX));
//! assert_eq(eth_signature.s, H256::from(EXPECTED_S_HEX));
//! assert_eq(eth_signature.v, H256::from(EXPECTED_V));
//! ```

pub mod ed25519;
pub mod ffi;
pub mod secp256k1;
pub mod starkex;
pub mod traits;
pub mod tw;

pub type KeyPairResult<T> = std::result::Result<T, KeyPairError>;

#[derive(Debug)]
pub enum KeyPairError {
    InvalidSecretKey,
    InvalidPublicKey,
    InvalidSignature,
    InvalidSignMessage,
    SignatureVerifyError,
    SigningError,
}
