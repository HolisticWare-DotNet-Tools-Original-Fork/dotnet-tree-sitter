# Zig cross-compilation toolchain for CMake.
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-zig.cmake
#                -DZIG_TARGET=x86_64-linux-gnu
#                -DZIG_CMAKE_SYSTEM_NAME=Linux

set(ZIG_TARGET "${ZIG_TARGET}" CACHE STRING "zig target triple")
set(ZIG_CMAKE_SYSTEM_NAME "${ZIG_CMAKE_SYSTEM_NAME}" CACHE STRING "CMake system name for target")

if(NOT ZIG_TARGET)
    message(FATAL_ERROR "ZIG_TARGET must be set (e.g. x86_64-linux-gnu)")
endif()

set(CMAKE_SYSTEM_NAME ${ZIG_CMAKE_SYSTEM_NAME})
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Use wrapper script so CMake finds a real executable, and zig ar for response file support on macOS.
set(ZIG_CROSS "${SCRIPT_DIR}/zig-cross" CACHE FILEPATH "zig cross-compiler wrapper" FORCE)
set(ZIG_BIN "${SCRIPT_DIR}/../../cmake/zig-ar-ranlib-helper" CACHE FILEPATH "zig archiver helper" FORCE)

set(CMAKE_C_COMPILER "${ZIG_CROSS}" CACHE FILEPATH "C compiler" FORCE)
set(CMAKE_AR "${ZIG_BIN}" CACHE FILEPATH "Archiver" FORCE)
set(CMAKE_RANLIB "${ZIG_BIN}" CACHE FILEPATH "Ranlib" FORCE)
