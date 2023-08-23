@echo off
setlocal enabledelayedexpansion

:: Initialize variables
set "FORCE="
set "PREFIX="
set "WALLET_PRJ_DIR="
set "PLUGIN_DIR="
set "ARCH="
set "TARGET_OS="

:: Parse command line arguments
:parse_args
if "%~1"=="" goto done_args
if "%~1"=="--protobuf-dir" (
    set "PREFIX=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--prj-dir" (
    set "WALLET_PRJ_DIR=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--plugin-dir" (
    set "PLUGIN_DIR=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--arch-abi" (
    set "ARCH=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--target-os" (
    set "TARGET_OS=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="-f" (
    set "FORCE=YES"
    shift
    goto parse_args
)
goto done_args

:done_args

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

:: Change directory to WALLET_PRJ_DIR if it is not empty
if not "!WALLET_PRJ_DIR!"=="" (
    cd "!WALLET_PRJ_DIR!"
)

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
codegen\bin\coins

:: Generate interface code, Swift bindings excluded.
codegen\bin\codegen

:: Generate Swift bindings with codegen-v2
cd codegen-v2
cargo run -- swift
copy /Y "bindings\*" "..\swift\Sources\Generated\"
copy /Y "src\codegen\swift\templates\WalletCore.h" "..\swift\Sources\Generated\"
cd ..

:: Convert doxygen comments to appropriate format
tools\doxygen_convert_comments

:bypass_coins

:: Generate Rust bindgen
tools\rust-bindgen %TARGET_OS% %ARCH%

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

:echo Generating Java code
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

:: Generate Proto interface file
"%PROTOC%" -I="%PREFIX%\include" -I=src\proto --plugin="%PLUGIN_DIR%\protoc-gen-c-typedef" --c-typedef_out include\TrustWalletCore src\proto\*.proto
"%PROTOC%" -I="%PREFIX%\include" -I=src\proto --plugin="%PLUGIN_DIR%\protoc-gen-swift-typealias" --swift-typealias_out swift\Sources\Generated\Protobuf src\proto\*.proto




:bypass_proto_interface



:: End of the script