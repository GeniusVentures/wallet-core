// Copyright © 2017-2023 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

#pragma once

#include "TWBase.h"

TW_EXTERN_C_BEGIN

typedef const void TWData;

/// Defines a resizable string.
///
/// The implementantion of these methods should be language-specific to minimize translation
/// overhead. For instance it should be a `jstring` for Java and an `NSString` for Swift. Create
/// allocates memory, the delete call should be called at the end to release memory.
typedef const void TWString;

/// Creates a string from a null-terminated UTF8 byte array. It must be deleted at the end.
TW_EXTERN
TWString *_Nonnull TWStringCreateWithUTF8Bytes(const char *_Nonnull bytes);

/// Creates a string from a raw byte array and size.
TW_EXTERN
TWString *_Nonnull TWStringCreateWithRawBytes(const uint8_t *_Nonnull bytes, size_t size);

/// Creates a hexadecimal string from a block of data. It must be deleted at the end.
TW_EXTERN
TWString *_Nonnull TWStringCreateWithHexData(TWData *_Nonnull data);

/// Returns the string size in bytes.
TW_EXTERN
size_t TWStringSize(TWString *_Nonnull string);

/// Returns the byte at the provided index.
TW_EXTERN
char TWStringGet(TWString *_Nonnull string, size_t index);

/// Returns the raw pointer to the string's UTF8 bytes (null-terminated).
TW_EXTERN
const char *_Nonnull TWStringUTF8Bytes(TWString *_Nonnull string);

/// Deletes a string created with a `TWStringCreate*` method.  After delete it must not be used (can segfault)!
TW_EXTERN
void TWStringDelete(TWString *_Nonnull string);

/// Determines whether two string blocks are equal.
TW_EXTERN
bool TWStringEqual(TWString *_Nonnull lhs, TWString *_Nonnull rhs);

TW_EXTERN_C_END
