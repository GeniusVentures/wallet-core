@echo off
setlocal enabledelayedexpansion

set "TARGET_NAME=libwallet_core_rs.a"
set "BUILD_FOLDER=..\rust\target"
set "CRATE=wallet-core-rs"
set "HEADER_NAME=WalletCoreRSBindgen.h"
set "TARGET_OS=%~1"
set "ARCH_ABI=%~2"
set "FORCE=%~3"

cd rust

:: Check if TARGET_OS is "windows"
if "%TARGET_OS%"=="windows" (
    :: Check if FORCE is set or $BUILD_FOLDER/release/$TARGET_NAME does not exist
    if "!FORCE!"=="" (
        if exist "!BUILD_FOLDER!\release\!TARGET_NAME!" (
            goto bypass_generate_targets
        )
    )
    echo Generating Native targets
	cargo build --release
	cargo build --target wasm32-unknown-emscripten --release --verbose

)

:bypass_generate_targets

:: Check if FORCE is set or ../src/rust/bindgen/$HEADER_NAME does not exist
if "!FORCE!"=="" (
    if exist "..\src\rust\bindgen\!HEADER_NAME!" (
        goto bypass_bindgen
    )
) 	
cbindgen --crate !CRATE! --output ..\src\rust\bindgen\!HEADER_NAME!

:bypass_bindgen

cd ..
