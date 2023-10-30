@echo off
setlocal enabledelayedexpansion

set "TARGET_NAME=wallet_core_rs.lib"
set "BUILD_FOLDER=..\rust\target"
set "CRATE=wallet-core-rs"
set "HEADER_NAME=WalletCoreRSBindgen.h"
set "WALLET_OUT_DIR="
set "ARCH_ABI="
set "TARGET_OS="
set "FORCE="

set "PARAM_ST="
:parse_args
if "%~1"=="" goto done_args
if "%~1"=="--out-dir" (
    set "PARAM_ST=%~1"
    shift
    goto parse_args
)
if "%~1"=="--arch-abi" (
    set "PARAM_ST=%~1"
    shift
    goto parse_args
)
if "%~1"=="--target-os" (
    set "PARAM_ST=%~1"
    shift
    goto parse_args
)
if "%~1"=="-f" (
    set "FORCE=YES"
    shift
    goto parse_args
)
if "!PARAM_ST!"=="--out-dir" (
    set "WALLET_OUT_DIR=%~1"
    shift
    goto parse_args
)
if "!PARAM_ST!"=="--arch-abi" (
    set "ARCH_ABI=%~1"
    shift
    goto parse_args
)
if "!PARAM_ST!"=="--target-os" (
    set "TARGET_OS=%~1"
    shift
    goto parse_args
)
goto done_args

:fix_paths
set "inputstr=!%~1!"
set "outputstr=%inputstr:/=\%"
set "%~1=!outputstr!"
exit /b

:done_args

call :fix_paths WALLET_OUT_DIR
call :fix_paths ARCH_ABI
call :fix_paths TARGET_OS

cd rust

if "%WALLET_OUT_DIR%"=="" (
    echo --out-dir not set. Defaulting to build\local
    set "ROOT=%CD%"
    set "WALLET_OUT_DIR=%ROOT%\build\local"
)
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

if "%TARGET_OS%"=="windows" (
    :: Check if $BUILD_FOLDER/release/$TARGET_NAME exists
    if exist "!BUILD_FOLDER!\release\!TARGET_NAME!" (
        md "%WALLET_OUT_DIR%\lib" -Recurse -Force
        copy "%BUILD_FOLDER%\release\%TARGET_NAME%" "%WALLET_OUT_DIR%\lib"
    )
)
:: Check if FORCE is set or ../src/rust/bindgen/$HEADER_NAME does not exist
if "!FORCE!"=="" (
    if exist "..\src\rust\bindgen\!HEADER_NAME!" (
        goto bypass_bindgen
    )
) 	
cbindgen --crate !CRATE! --output ..\src\rust\bindgen\!HEADER_NAME!

:bypass_bindgen

cd ..
