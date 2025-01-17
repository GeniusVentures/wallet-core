// Copyright © 2017-2023 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.
#pragma once

#include "TWBase.h"
#include "TWCoinType.h"
#include "TWData.h"
#include "TWString.h"

TW_EXTERN_C_BEGIN

/// Represents a signer to sign transactions for any blockchain.
struct TWAnySigner;

/// Signs a transaction.
TW_EXTERN
extern TWData *_Nonnull TWAnySignerSign(TWData *_Nonnull input, enum TWCoinType coin);

/// Signs a json transaction with private key.
TW_EXTERN
extern TWString *_Nonnull TWAnySignerSignJSON(TWString *_Nonnull json, TWData *_Nonnull key, enum TWCoinType coin);

TW_EXTERN
extern bool TWAnySignerSupportsJSON(enum TWCoinType coin);

/// Plan a transaction (for UTXO chains).
TW_EXTERN
extern TWData *_Nonnull TWAnySignerPlan(TWData *_Nonnull input, enum TWCoinType coin);

TW_EXTERN_C_END
