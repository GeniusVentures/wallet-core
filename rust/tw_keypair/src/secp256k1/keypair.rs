// Copyright © 2017-2023 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

use crate::secp256k1::private::PrivateKey;
use crate::secp256k1::public::PublicKey;
use crate::secp256k1::{Signature, VerifySignature};
use crate::traits::{KeyPairTrait, SigningKeyTrait, VerifyingKeyTrait};
use crate::{KeyPairError, KeyPairResult};
use tw_encoding::hex;
use tw_hash::H256;
use zeroize::Zeroizing;

/// Represents a pair of `secp256k1` private and public keys.
pub struct KeyPair {
    private: PrivateKey,
    public: PublicKey,
}

impl KeyPairTrait for KeyPair {
    type Private = PrivateKey;
    type Public = PublicKey;

    fn public(&self) -> &Self::Public {
        &self.public
    }

    fn private(&self) -> &Self::Private {
        &self.private
    }
}

impl SigningKeyTrait for KeyPair {
    type SigningMessage = H256;
    type Signature = Signature;

    fn sign(&self, message: Self::SigningMessage) -> KeyPairResult<Self::Signature> {
        self.private.sign(message)
    }
}

impl VerifyingKeyTrait for KeyPair {
    type SigningMessage = H256;
    type VerifySignature = VerifySignature;

    fn verify(&self, signature: Self::VerifySignature, message: Self::SigningMessage) -> bool {
        self.public.verify(signature, message)
    }
}

impl<'a> TryFrom<&'a [u8]> for KeyPair {
    type Error = KeyPairError;

    fn try_from(bytes: &'a [u8]) -> Result<Self, Self::Error> {
        let private = PrivateKey::try_from(bytes)?;
        let public = private.public();
        Ok(KeyPair { private, public })
    }
}

impl<'a> TryFrom<&'a str> for KeyPair {
    type Error = KeyPairError;

    fn try_from(hex: &'a str) -> Result<Self, Self::Error> {
        let bytes = Zeroizing::new(hex::decode(hex).map_err(|_| KeyPairError::InvalidSecretKey)?);
        Self::try_from(bytes.as_slice())
    }
}
