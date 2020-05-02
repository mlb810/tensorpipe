# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

cmake_minimum_required(VERSION 3.5 FATAL_ERROR)

project(tensorpipe LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 14)

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

# We use the [[nodiscard]] attribute, which GCC 5 complains about.
# Silence this warning if GCC 5 is used.
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 6)
    add_definitions("-Wno-attributes")
  endif()
endif()


## Core

set(TENSORPIPE_PUBLIC_HEADERS
  tensorpipe/core/error.h
  tensorpipe/core/listener.h
  tensorpipe/core/context.h
  tensorpipe/core/message.h
  tensorpipe/core/pipe.h
  tensorpipe/channel/error.h
  tensorpipe/channel/channel.h
  tensorpipe/channel/context.h
  tensorpipe/channel/helpers.h
  tensorpipe/common/error_macros.h
  tensorpipe/common/error.h
  tensorpipe/common/defs.h
  tensorpipe/common/address.h
  tensorpipe/common/optional.h
  tensorpipe/common/system.h
  tensorpipe/common/callback.h
  tensorpipe/common/queue.h
  tensorpipe/transport/connection.h
  tensorpipe/transport/context.h
  tensorpipe/transport/defs.h
  tensorpipe/transport/error.h
  tensorpipe/transport/listener.h
  tensorpipe/transport/registry.h
  tensorpipe/util/registry/registry.h
  tensorpipe/tensorpipe.h)

set(TENSORPIPE_SRC
  tensorpipe/channel/context.cc
  tensorpipe/channel/error.cc
  tensorpipe/channel/helpers.cc
  tensorpipe/channel/registry.cc
  tensorpipe/common/address.cc
  tensorpipe/common/error.cc
  tensorpipe/common/system.cc
  tensorpipe/core/context.cc
  tensorpipe/core/error.cc
  tensorpipe/core/listener.cc
  tensorpipe/core/pipe.cc
  tensorpipe/proto/core.proto
  tensorpipe/transport/connection.cc
  tensorpipe/transport/error.cc
  tensorpipe/transport/registry.cc)


## Channels

### basic

list(APPEND TENSORPIPE_PUBLIC_HEADERS tensorpipe/channel/basic/context.h)
list(APPEND TENSORPIPE_SRC
  tensorpipe/channel/basic/channel.cc
  tensorpipe/channel/basic/context.cc
  tensorpipe/proto/channel/basic.proto)

### cma

if(TP_ENABLE_CMA)
  list(APPEND TENSORPIPE_PUBLIC_HEADERS tensorpipe/channel/cma/context.h)
  list(APPEND TENSORPIPE_SRC
    tensorpipe/channel/cma/channel.cc
    tensorpipe/channel/cma/context.cc
    tensorpipe/proto/channel/cma.proto)
endif()


## Transports

### uv

list(APPEND TENSORPIPE_PUBLIC_HEADERS tensorpipe/transport/uv/context.h)
list(APPEND TENSORPIPE_SRC
  tensorpipe/transport/uv/connection.cc
  tensorpipe/transport/uv/context.cc
  tensorpipe/transport/uv/error.cc
  tensorpipe/transport/uv/listener.cc
  tensorpipe/transport/uv/loop.cc
  tensorpipe/transport/uv/sockaddr.cc
  tensorpipe/transport/uv/uv.cc)

### shm

if(TP_ENABLE_SHM)
  list(APPEND TENSORPIPE_PUBLIC_HEADERS tensorpipe/transport/shm/context.h)
  list(APPEND TENSORPIPE_SRC
    tensorpipe/transport/shm/context.cc
    tensorpipe/transport/shm/connection.cc
    tensorpipe/transport/shm/fd.cc
    tensorpipe/transport/shm/listener.cc
    tensorpipe/transport/shm/loop.cc
    tensorpipe/transport/shm/reactor.cc
    tensorpipe/transport/shm/socket.cc
    tensorpipe/util/ringbuffer/shm.cc
    tensorpipe/util/shm/segment.cc)
endif()


## Main target

add_library(tensorpipe ${TENSORPIPE_SRC})

set(TP_BUILD_LIBUV ON)
find_package(uv REQUIRED)
target_link_libraries(tensorpipe PRIVATE uv::uv)

# Support `#include <tensorpipe/foo.h>`.
target_include_directories(tensorpipe PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>)

if(NOT TARGET protobuf::libprotobuf)
  find_package(Protobuf 3 REQUIRED)
endif()

target_link_libraries(tensorpipe PRIVATE protobuf::libprotobuf)

# Support `#include <tensorpipe/proto/foo.pb.h>`.
target_include_directories(tensorpipe PRIVATE ${PROJECT_BINARY_DIR})

# Support `#include "proto/foo.pb.h"`, as generated by protoc.
target_include_directories(tensorpipe PRIVATE ${PROJECT_BINARY_DIR}/tensorpipe)

include(cmake/ProtobufGenerate.cmake)
protobuf_generate(TARGET tensorpipe)


## Installing

include(GNUInstallDirs)
foreach (file ${TENSORPIPE_PUBLIC_HEADERS})
  get_filename_component(dir ${file} DIRECTORY)
  install(FILES ${file}
          DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}/${dir})
endforeach()
install(TARGETS tensorpipe
        EXPORT tensorpipe-targets
        LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
        ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
install(EXPORT tensorpipe-targets
        DESTINATION share/cmake/tensorpipe
        FILE TensorpipeTargets.cmake)
