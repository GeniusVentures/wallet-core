# Copyright © 2017-2022 Trust Wallet.
#
# This file is part of Trust. The full Trust copyright notice, including
# terms governing use, modification, and redistribution, is contained in the
# file LICENSE at the root of the source code distribution tree.

cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

project(TrustWalletCore)

include(GNUInstallDirs)

# Configure warnings
if(NOT ("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC"))
    set(TW_CXX_WARNINGS "-Wno-shorten-64-to-32 -Wno-deprecated-volatile -Wno-double-promotion")
endif()
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${TW_CXX_WARNINGS}")
set(CMAKE_EXPORT_COMPILE_COMMANDS 1)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)

if ("$ENV{PREFIX}" STREQUAL "")
    set(PREFIX "${CMAKE_SOURCE_DIR}/build/local")
else ()
    set(PREFIX "$ENV{PREFIX}")
endif ()

include(cmake/StandardSettings.cmake)
include(cmake/CompilerWarnings.cmake)
include(cmake/StaticAnalyzers.cmake)
include(cmake/FindHostPackage.cmake)

if((NOT ("${CMAKE_CXX_COMPILER_ID}" MATCHES ".*Clang")) AND (NOT ("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC")))
    message("You should use clang or msvc compiler, got ${CMAKE_CXX_COMPILER_ID}, switching to clang...")
    set(CMAKE_CXX_COMPILER clang++)
    set(CMAKE_C_COMPILER clang)
endif()


set(WALLET_CORE_RS_TARGET_DIR ${CMAKE_SOURCE_DIR}/rust/target)
add_library(${PROJECT_NAME}_INTERFACE INTERFACE)
target_include_directories(${PROJECT_NAME}_INTERFACE INTERFACE ${PREFIX}/include)
target_link_directories(${PROJECT_NAME}_INTERFACE INTERFACE ${PREFIX}/lib)
target_link_directories(${PROJECT_NAME}_INTERFACE INTERFACE ${WALLET_CORE_RS_TARGET_DIR}/release)
set_project_warnings(${PROJECT_NAME}_INTERFACE)

if(WIN32)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS -DTW_STATIC_LIBRARY) # Disable strcpy warnings
endif()

add_subdirectory(trezor-crypto)
set(WALLET_CORE_RS_LIB libwallet_core_rs.a)

set(WALLET_CORE_BINDGEN ${WALLET_CORE_RS_TARGET_DIR}/release/${WALLET_CORE_RS_LIB})
if (TW_COMPILE_WASM)
    message(STATUS "Wasm build enabled")
    set(WALLET_CORE_BINDGEN ${WALLET_CORE_RS_TARGET_DIR}/wasm32-unknown-emscripten/release/${WALLET_CORE_RS_LIB})
    add_subdirectory(wasm)
endif ()

find_package(Boost CONFIG REQUIRED)

include(ExternalProject)

if (TW_USE_EXTERNAL_PROTOC)
    find_package(Protobuf CONFIG REQUIRED)
    include_directories(${Protobuf_INCLUDE_DIRS})
else()
    # Dependencies
    include(cmake/Protobuf.cmake)
endif()

# Source files
if (${ANDROID})
    message("Configuring for JNI")
    file(GLOB_RECURSE core_sources src/*.c src/*.cc src/*.cpp src/*.h jni/cpp/*.cpp jni/cpp/*.h)
    if (${KOTLIN})
        file(GLOB_RECURSE specific_sources
                jni/kotlin/*.h
                jni/kotlin/*.c
                kotlin/wallet-core-kotlin/src/androidMain/cpp/generated/*.h
                kotlin/wallet-core-kotlin/src/androidMain/cpp/generated/*.c
                )
    else ()
        file(GLOB_RECURSE specific_sources jni/android/*.h jni/android/*.c)
    endif ()
    set(sources ${core_sources} ${specific_sources})
    add_library(TrustWalletCore STATIC ${sources} ${PROTO_SRCS} ${PROTO_HDRS})
    find_library(log-lib log)
    if (${CMAKE_ANDROID_ARCH_ABI} STREQUAL "arm64-v8a")
        set(WALLET_CORE_BINDGEN ${WALLET_CORE_RS_TARGET_DIR}/aarch64-linux-android/release/${WALLET_CORE_RS_LIB})
    elseif (${CMAKE_ANDROID_ARCH_ABI} STREQUAL "x86")
        set(WALLET_CORE_BINDGEN ${WALLET_CORE_RS_TARGET_DIR}/i686-linux-android/release/${WALLET_CORE_RS_LIB})
    elseif (${CMAKE_ANDROID_ARCH_ABI} STREQUAL "armeabi-v7a")
        set(WALLET_CORE_BINDGEN ${WALLET_CORE_RS_TARGET_DIR}/armv7-linux-androideabi/release/${WALLET_CORE_RS_LIB})
    elseif (${CMAKE_ANDROID_ARCH_ABI} STREQUAL "x86_64")
        set(WALLET_CORE_BINDGEN ${WALLET_CORE_RS_TARGET_DIR}/x86_64-linux-android/release/${WALLET_CORE_RS_LIB})
    endif ()
    target_link_libraries(TrustWalletCore PUBLIC ${WALLET_CORE_BINDGEN} ${PROJECT_NAME}_INTERFACE PRIVATE TrezorCrypto ${Protobuf_LIBRARIES} ${log-lib} Boost::boost)
else()
    file(GLOB_RECURSE sources src/*.c src/*.cc src/*.cpp src/*.h)
    if(WIN32)
        file(GLOB_RECURSE headers include/TrustWalletCore/*.h)
        if(TW_STATIC_LIBRARY)
            message("Configuring static for Windows")
            add_library(TrustWalletCore ${sources} ${headers} ${PROTO_SRCS} ${PROTO_HDRS})
        else()
            message("Configuring shared for Windows")
            add_library(TrustWalletCore SHARED ${sources} ${headers} ${PROTO_SRCS} ${PROTO_HDRS})
            target_compile_definitions(TrustWalletCore PRIVATE TW_EXPORT_LIBRARY)
        endif()
        target_link_libraries(TrustWalletCore PRIVATE TrezorCrypto ${Protobuf_LIBRARIES} Boost::boost)
    else()
        message("Configuring standalone")
        add_library(TrustWalletCore ${sources} ${PROTO_SRCS} ${PROTO_HDRS})
        target_link_libraries(TrustWalletCore PUBLIC ${WALLET_CORE_BINDGEN} ${PROJECT_NAME}_INTERFACE PRIVATE TrezorCrypto ${Protobuf_LIBRARIES} Boost::boost)
    endif()
endif()


if (TW_CODE_COVERAGE AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|.*Clang")
    target_enable_coverage(TrustWalletCore)
endif ()

if(NOT ("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC"))
    target_compile_options(TrustWalletCore PRIVATE "-Wall")
endif()

if (TW_CLANG_ASAN)
    target_enable_asan(TrustWalletCore)
endif ()

# Define headers for this library. PUBLIC headers are used for compiling the
# library, and will be added to consumers' build paths.
target_include_directories(TrustWalletCore
        PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/jni/cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/build/local/include
        ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/json/include
        )

if (TW_UNIT_TESTS)
    add_subdirectory(tests)
endif ()

if (TW_BUILD_EXAMPLES)
    add_subdirectory(walletconsole/lib)
    add_subdirectory(walletconsole)
endif ()

if (TW_ENABLE_PVS_STUDIO)
    tw_add_pvs_studio_target(TrustWalletCore)
endif ()

if (TW_ENABLE_CLANG_TIDY)
    tw_add_clang_tidy_target(TrustWalletCore)
endif ()

if (TW_UNITY_BUILD)
    set_target_properties(TrustWalletCore PROPERTIES UNITY_BUILD ON)

    file(GLOB_RECURSE PROTOBUF_SOURCE_FILES CONFIGURE_DEPENDS src/Cosmos/Protobuf/*.pb.cc src/Hedera/Protobuf/*.pb.cc src/proto/*.pb.cc)
    foreach (file ${PROTOBUF_SOURCE_FILES})
        set_property(SOURCE ${file} PROPERTY SKIP_UNITY_BUILD_INCLUSION ON)
    endforeach ()
    message(STATUS "Unity build activated")
endif ()

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/swift/cpp.xcconfig.in ${CMAKE_CURRENT_SOURCE_DIR}/swift/cpp.xcconfig @ONLY)

if(WIN32 AND NOT TW_STATIC_LIBRARY)
    install(TARGETS TrustWalletCore RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

install(TARGETS TrustWalletCore
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        )

install(
        DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/WalletCore
        FILES_MATCHING PATTERN "*.h"
)

install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
