cmake_minimum_required(VERSION 3.30.0)
project(module VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

find_package(PostgreSQL REQUIRED)

set(PostgreSQL_COMPILE_OPTIONS
  ${PostgreSQL_COMPILE_OPTIONS}
    -Werror
    -Wall
    -fvisibility=hidden
    -fvisibility-inlines-hidden
)

option(ENABLE_COVERAGE "Enable coverage reporting" OFF)

if(ENABLE_COVERAGE)
  if(NOT "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")                      # If coverage is required on non-DEBUG builds,
    message(FATAL_ERROR "Coverage requires a debug build type!")      # Then error out.
  endif()
  set(PostgreSQL_COMPILE_OPTIONS ${PostgreSQL_COMPILE_OPTIONS} --coverage)
  set(PostgreSQL_LINK_OPTIONS ${PostgreSQL_LINK_OPTIONS} --coverage)
endif()
message(STATUS "Coverage ${ENABLE_COVERAGE}")

enable_testing()

file(
  GLOB_RECURSE
  SOURCE_CPP
  CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
)

file(
  GLOB_RECURSE
  SOURCE_CPPM
  CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cppm
)

add_postgresql_extension(
  quaternion
  VERSION 1.0
  SOURCES ${SOURCE_CPP}
  MOUDULES ${SOURCE_CPPM}
  SCRIPTS src/quaternion--1.0.sql
)

set(CHECK_SRCS ${SOURCE_CPP} ${SOURCE_CPPM})

# clang-format
add_custom_target(check-format
  COMMAND clang-format --style=file --dry-run -Werror -i  ${CHECK_SRCS}
  VERBATIM
)

# clang-tidy
add_custom_target(check-tidy
  COMMAND clang-tidy-18 -p=${CMAKE_BINARY_DIR} --config-file=${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy ${CHECK_SRCS}
  VERBATIM
)