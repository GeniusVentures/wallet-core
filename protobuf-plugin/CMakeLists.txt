# Copyright © 2017-2022 Trust Wallet.
#
# This file is part of Trust. The full Trust copyright notice, including
# terms governing use, modification, and redistribution, is contained in the
# file LICENSE at the root of the source code distribution tree.

cmake_minimum_required(VERSION 3.2 FATAL_ERROR)
project(TrustWalletCoreProtobufPlugin)

set(CMAKE_OSX_DEPLOYMENT_TARGET "12.1" CACHE STRING "Minimum OS X deployment version" FORCE)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if (TW_USE_EXTERNAL_PROTOC)
    find_package(Protobuf CONFIG REQUIRED)
    link_directories(${Protobuf_LIB_DIR})
else()
    set(TW_BUILD_PREFIX "${CMAKE_SOURCE_DIR}/../build/local")
    set(Protobuf_INCLUDE_DIR ${TW_BUILD_PREFIX}/include)
    link_directories(${TW_BUILD_PREFIX}/lib)
    find_package(Protobuf REQUIRED PATH ${TW_BUILD_PREFIX}/lib/pkgconfig)
endif()

include_directories(${Protobuf_INCLUDE_DIR})
include_directories(${CMAKE_CURRENT_BINARY_DIR})

if (NOT ("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC"))
    set(TW_PTHREAD_LIB "-pthread" )
endif()

if (TW_STATIC_LIBRARY)
    set(TW_STATIC_PRIVATE PRIVATE)
endif()

add_executable(protoc-gen-c-typedef c_typedef.cc ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(protoc-gen-c-typedef ${TW_STATIC_PRIVATE} ${Protobuf_LIBRARIES} ${Protobuf_PROTOC_LIBRARIES} ${TW_PTHREAD_LIB})

add_executable(protoc-gen-swift-typealias swift_typealias.cc ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(protoc-gen-swift-typealias ${Protobuf_LIBRARIES} ${Protobuf_PROTOC_LIBRARIES} )

install(TARGETS protoc-gen-c-typedef protoc-gen-swift-typealias DESTINATION bin)
