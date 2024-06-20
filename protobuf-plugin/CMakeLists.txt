# Copyright © 2017-2022 Trust Wallet.
#
# This file is part of Trust. The full Trust copyright notice, including
# terms governing use, modification, and redistribution, is contained in the
# file LICENSE at the root of the source code distribution tree.

cmake_minimum_required(VERSION 3.5 FATAL_ERROR)
project(TrustWalletCoreProtobufPlugin)

set(CMAKE_OSX_DEPLOYMENT_TARGET "12.1" CACHE STRING "Minimum OS X deployment version" FORCE)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if("$ENV{PREFIX}" STREQUAL "")
    set(PREFIX "${CMAKE_SOURCE_DIR}/../build/local")
else()
    set(PREFIX "$ENV{PREFIX}")
endif()

find_package(Protobuf CONFIG REQUIRED PATH ${PREFIX}/lib/pkgconfig)

add_executable(protoc-gen-c-typedef c_typedef.cc)
target_link_libraries(protoc-gen-c-typedef protobuf::libprotobuf protobuf::libprotoc)

add_executable(protoc-gen-swift-typealias swift_typealias.cc)
target_link_libraries(protoc-gen-swift-typealias protobuf::libprotobuf protobuf::libprotoc)

install(TARGETS protoc-gen-c-typedef protoc-gen-swift-typealias DESTINATION bin)
