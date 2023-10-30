@echo off
setlocal enabledelayedexpansion

:: Initialize variables
set "FORCE="
set "PREFIX="
set "WALLET_OUT_DIR="
set "PLUGIN_DIR="
set "ARCH="
set "TARGET_OS="

:: Parse command line arguments

set "PARAM_ST="
:parse_args
if "%~1"=="" goto done_args
if "%~1"=="--protobuf-dir" (
    set "PARAM_ST=%~1"
    shift
    goto parse_args
)
if "%~1"=="--out-dir" (
    set "PARAM_ST=%~1"
    shift
    goto parse_args
)
if "%~1"=="--plugin-dir" (
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
if "!PARAM_ST!"=="--protobuf-dir" (
    set "PREFIX=%~1"
    shift
    goto parse_args
)
if "!PARAM_ST!"=="--out-dir" (
    set "WALLET_OUT_DIR=%~1"
    shift
    goto parse_args
)
if "!PARAM_ST!"=="--plugin-dir" (
    set "PLUGIN_DIR=%~1"
    shift
    goto parse_args
)
if "!PARAM_ST!"=="--arch-abi" (
    set "ARCH=%~1"
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

call :fix_paths PREFIX
call :fix_paths WALLET_OUT_DIR
call :fix_paths PLUGIN_DIR
call :fix_paths ARCH
call :fix_paths TARGET_OS

if "%PREFIX%"=="" (
    rem PREFIX not set
    set "ROOT=%CD%"
    set "PREFIX=%ROOT%\build\local"
    if not exist "%PREFIX%" (
        echo PREFIX does not exist, falling back to C:\Program Files
        set "PREFIX=C:\Program Files"
    ) else (
        if not exist "%PREFIX%\include" (
            echo Include directory does not exist in PREFIX, falling back to C:\Program Files
            set "PREFIX=C:\Program Files"
        ) else (
            if not exist "%PREFIX%\bin\protoc" (
                echo protoc does not exist in PREFIX, falling back to C:\Program Files
                set "PREFIX=C:\Program Files"
            ) else (
                if not exist "%PREFIX%\bin\protoc-gen-c-typedef" (
                    echo protoc-gen-c-typedef does not exist in PREFIX, falling back to C:\Program Files
                    set "PREFIX=C:\Program Files"
                )
            )
        )
    )
)

echo PREFIX: !PREFIX!
echo ARCH: !ARCH!
echo TARGET_OS: !TARGET_OS!
echo WALLET_OUT_DIR: !WALLET_OUT_DIR!
echo PLUGIN_DIR: !PLUGIN_DIR!
echo FORCE: !FORCE!

set "PATH=!PREFIX!\bin;!PATH!"

:: TODO - Check if needed.
::set "LD_LIBRARY_PATH"=!PREFIX!\lib;!LD_LIBRARY_PATH!"
::set "DYLD_LIBRARY_PATH"=!PREFIX!\lib;!DYLD_LIBRARY_PATH!"

set "PROTOC=!PREFIX!\bin\protoc"
echo PROTOC: !PROTOC!

!PROTOC! --version



:: Check if FORCE is set or swift/Sources/Generated/WalletCore.h does not exist
if "!FORCE!"=="" (
    if exist "swift\Sources\Generated\WalletCore.h" (
        goto bypass_coins
    )
)

echo Generating coins and interface code.

:: Clean
rmdir /s /q "swift\Sources\Generated"
rmdir /s /q "jni\java\wallet\core\jni"
rmdir /s /q "jni\android\generated"

mkdir "swift\Sources\Generated\Protobuf"
mkdir "swift\Sources\Generated\Enums"



:: Generate coins info from registry.json
ruby.exe codegen\bin\coins

:: Generate interface code, Swift bindings excluded.
ruby.exe codegen\bin\codegen


:: Generate Swift bindings with codegen-v2
cd codegen-v2
cargo run -- swift
copy /Y "bindings\*" "..\swift\Sources\Generated\"
copy /Y "src\codegen\swift\templates\WalletCore.h" "..\swift\Sources\Generated\"
cd ..

:: Convert doxygen comments to appropriate format TODO - Remove or port this
::tools\doxygen_convert_comments 

:bypass_coins
set "FORCE_RUST="

 if not "!FORCE!"=="" (
    set "FORCE_RUST=-f"
)

:: Generate Rust bindgen
call tools\win-rust-bindgen.bat --target-os=%TARGET_OS% --arch-abi=%ARCH% --out-dir=%WALLET_OUT_DIR% %FORCE_RUST%

:: Check if protoc-gen-swift is available and no command line arguments are provided
if exist "%PREFIX%\bin\protoc-gen-swift" (
    if "%~1"=="" (
        goto generate_swift
    )
)

:: Otherwise, generate Java and C++ Protobuf files
goto generate_java_cpp

:generate_swift
if "!FORCE!"=="" (
    if exist "swift\Sources\Generated\Protobuf\Aeternity+Proto.swift" (
        goto bypass_swift_java
    )
)

echo Generating Swift code
"%PROTOC%" -I="%PREFIX%\include" -I=src/proto --cpp_out=src/proto --java_out=lite:jni/proto --swift_out=swift\Sources\Generated\Protobuf --swift_opt=Visibility=Public src/proto\*.proto
goto bypass_swift_java

:generate_java_cpp
if "!FORCE!"=="" (
    if exist "jni\proto\wallet\core\jni\proto\Aeternity.java" (
        goto bypass_swift_java
    )
)

echo Generating Java code
"%PROTOC%" -I="%PREFIX%\include" -I=src/proto --cpp_out=src/proto --java_out=lite:jni/proto src/proto\*.proto

:bypass_swift_java

:: Check if FORCE is set or src\Hedera\Protobuf\transaction_contents.pb.h does not exist
if "!FORCE!"=="" (
    if exist "src\Hedera\Protobuf\transaction_contents.pb.h" (
        goto bypass_internal_protobuf
    )
)

echo Generating internal protobuf files

:: Generate Protobuf files for various directories
"%PROTOC%" -I="%PREFIX%\include" -I=src\Tron\Protobuf --cpp_out=src\Tron\Protobuf src\Tron\Protobuf\*.proto
"%PROTOC%" -I="%PREFIX%\include" -I=src\Zilliqa\Protobuf --cpp_out=src\Zilliqa\Protobuf src\Zilliqa\Protobuf\*.proto
"%PROTOC%" -I="%PREFIX%\include" -I=src\Cosmos\Protobuf --cpp_out=src\Cosmos\Protobuf src\Cosmos\Protobuf\*.proto
"%PROTOC%" -I="%PREFIX%\include" -I=src\Hedera\Protobuf --cpp_out=src\Hedera\Protobuf src\Hedera\Protobuf\*.proto
"%PROTOC%" -I="%PREFIX%\include" -I=tests\chains\Cosmos\Protobuf --cpp_out=tests\chains\Cosmos\Protobuf tests\chains\Cosmos\Protobuf\*.proto

:bypass_internal_protobuf

:: Check if FORCE is set or src\Hedera\Protobuf\transaction_contents.pb.h does not exist
if "!FORCE!"=="" (
    if exist "include\TrustWalletCore\TWOntologyProto.h" (
        goto bypass_proto_interface
    )
)

if "!PLUGIN_DIR!"=="" (
    set "PLUGIN_DIR=%PREFIX%\bin"
)

echo Generating proto interface files

set "path=%path%;%PLUGIN_DIR%"
:: Generate Proto interface file
"%PROTOC%" -I="%PREFIX%\include" -I=src\proto --c-typedef.exe_out include\TrustWalletCore src\proto\*.proto
"%PROTOC%" -I="%PREFIX%\include" -I=src\proto --swift-typealias.exe_out swift\Sources\Generated\Protobuf src\proto\*.proto

:bypass_proto_interface
