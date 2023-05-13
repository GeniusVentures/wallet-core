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
    find_package(Protobuf REQUIRED)
    link_directories(${Protobuf_LIB_DIR})
else()
    option(TW_BUILD_PREFIX "${CMAKE_SOURCE_DIR}/../build/local")
    include_directories(${TW_BUILD_PREFIX}/include)
    link_directories(${TW_BUILD_PREFIX}/lib)
    find_package(Protobuf REQUIRED PATH ${TW_BUILD_PREFIX}/lib/pkgconfig)
endif()

include_directories(${Protobuf_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_executable(protoc-gen-c-typedef c_typedef.cc ${PROTO_SRCS} ${PROTO_HDRS})
if (NOT ("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC"))
    set(TW_PTHREAD_LIB "-pthread" )
endif()

if (("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC"))
    target_link_libraries(protoc-gen-c-typedef ${Protobuf_LIBRARIES} ${Protobuf_PROTOC_LIBRARIES})
else()
    target_link_libraries(protoc-gen-c-typedef -lprotobuf -lprotoc -pthread)
endif()
add_executable(protoc-gen-swift-typealias swift_typealias.cc ${PROTO_SRCS} ${PROTO_HDRS})
if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC")
    target_link_libraries(protoc-gen-swift-typealias ${Protobuf_LIBRARIES} ${Protobuf_PROTOC_LIBRARIES} )
else()
    target_link_libraries(protoc-gen-swift-typealias -lprotobuf -lprotoc -pthread)
endif()

install(TARGETS protoc-gen-c-typedef protoc-gen-swift-typealias DESTINATION bin)
