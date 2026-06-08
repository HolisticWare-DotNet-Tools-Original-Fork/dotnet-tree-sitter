# Generic zig cross-compilation toolchain for CMake.
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-zig.cmake
#                -DZIG_TARGET=x86_64-linux-gnu
#                -DZIG_CMAKE_SYSTEM_NAME=Linux
#                -DTREE_SITTER_OUTPUT_DIR=...

# Ensure these propagate into recursive try-compile calls
set(ZIG_TARGET "${ZIG_TARGET}" CACHE STRING "zig target triple")
set(ZIG_CMAKE_SYSTEM_NAME "${ZIG_CMAKE_SYSTEM_NAME}" CACHE STRING "CMake system name for target")

if(NOT ZIG_TARGET)
    message(FATAL_ERROR "ZIG_TARGET must be set (e.g. x86_64-linux-gnu)")
endif()

set(CMAKE_SYSTEM_NAME ${ZIG_CMAKE_SYSTEM_NAME})
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Use zig as the C compiler, linker, and archiver
find_program(ZIG_CC zig PATHS /opt/homebrew/bin /usr/local/bin /usr/bin)
if(NOT ZIG_CC)
    message(FATAL_ERROR "zig not found in PATH")
endif()

set(CMAKE_C_COMPILER "${ZIG_CC}" CACHE FILEPATH "C compiler" FORCE)
set(CMAKE_C_FLAGS "-target ${ZIG_TARGET}" CACHE STRING "" FORCE)

# Zig's `cc` subcommand handles both compilation and linking
set(CMAKE_LINKER "${ZIG_CC}" CACHE FILEPATH "" FORCE)

# Set CMAKE_FIND_ROOT_PATH to avoid host system pollution
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
