#!/bin/sh
#
# Build all native tree-sitter libraries with CMake.
# Produces .so/.dylib/.dll files in native/out/{platform}/
# to match the layout expected by the .NET bindings.
#
# Usage:
#   ./native/build-all.sh osx-arm64        # macOS Apple Silicon (native)
#   ./native/build-all.sh osx-x64          # macOS Intel (native)
#   ./native/build-all.sh linux-x64        # Linux x86_64 (requires x86_64-linux-gnu-gcc on non-Linux hosts)
#   ./native/build-all.sh linux-arm64      # Linux ARM64 (requires aarch64-linux-gnu-gcc on non-Linux hosts)
#   ./native/build-all.sh win-x64          # Windows x86_64 (requires mingw-w64 on non-Windows hosts)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLCHAIN_DIR="${SCRIPT_DIR}/cmake"
PLATFORM="${1:-}"

if [ -z "$PLATFORM" ]; then
    echo "Usage: $0 <platform>"
    echo "Platforms: osx-arm64, osx-x64, linux-x64, linux-arm64, win-x64"
    exit 1
fi

OUTDIR="${SCRIPT_DIR}/out/${PLATFORM}"
BUILDDIR="${SCRIPT_DIR}/build-cmake"

# Map platform to CMake system name and toolchain file
case "$PLATFORM" in
    osx-arm64|osx-x64)
        SYSTEM_NAME="Darwin"
        TOOLCHAIN=""
        ;;
    linux-x64)
        SYSTEM_NAME="Linux"
        TOOLCHAIN="${TOOLCHAIN_DIR}/toolchain-linux-x64.cmake"
        ;;
    linux-arm64)
        SYSTEM_NAME="Linux"
        TOOLCHAIN="${TOOLCHAIN_DIR}/toolchain-linux-arm64.cmake"
        ;;
    win-x64)
        SYSTEM_NAME="Windows"
        TOOLCHAIN="${TOOLCHAIN_DIR}/toolchain-win-x64.cmake"
        ;;
    *)
        echo "Unknown platform: ${PLATFORM}"
        echo "Platforms: osx-arm64, osx-x64, linux-x64, linux-arm64, win-x64"
        exit 1
        ;;
esac

# Detect host OS
HOST_OS="$(uname -s)"
case "$SYSTEM_NAME" in
    Darwin)   HOST_MATCH="Darwin" ;;
    Linux)    HOST_MATCH="Linux" ;;
    Windows)  HOST_MATCH="Windows" ;;
    *)        HOST_MATCH="" ;;
esac

# Check if we're cross-compiling (target differs from host)
CROSS_COMPILE=0
if [ "$HOST_OS" != "$SYSTEM_NAME" ]; then
    CROSS_COMPILE=1
fi

# If cross-compiling, verify toolchain file exists and compiler is available
if [ $CROSS_COMPILE -eq 1 ] && [ -n "$TOOLCHAIN" ]; then
    if [ ! -f "$TOOLCHAIN" ]; then
        echo "ERROR: Cross-compile toolchain not found: ${TOOLCHAIN}"
        echo "Install cross-compilers:"
        echo "  Linux x64:  apt install gcc-x86-64-linux-gnu (Debian/Ubuntu) or yum install gcc-x86_64-linux-gnu (RHEL)"
        echo "  Linux ARM64: apt install gcc-aarch64-linux-gnu (Debian/Ubuntu) or yum install gcc-aarch64-linux-gnu (RHEL)"
        echo "  Windows:    brew install mingw-w64 (macOS)"
        exit 1
    fi
    
    # Extract compiler from toolchain and check availability
    COMPILER=$(grep "CMAKE_C_COMPILER" "$TOOLCHAIN" | sed 's/^set(CMAKE_C_COMPILER //;s/)$//')
    if ! command -v "$COMPILER" &>/dev/null; then
        echo "ERROR: Cross-compiler not found: ${COMPILER}"
        echo "Install it first, or run this build script natively on the target platform."
        exit 1
    fi
    
    echo "Cross-compiling $PLATFORM (host: $HOST_OS) using $COMPILER"
fi

echo "Building for ${PLATFORM} -> ${OUTDIR}"

# Configure
CMAKE_ARGS=(
    -S "${SCRIPT_DIR}"
    -B "${BUILDDIR}"
    -DTREE_SITTER_OUTPUT_DIR="${OUTDIR}"
    -DCMAKE_BUILD_TYPE=Release
)

if [ -n "$TOOLCHAIN" ]; then
    CMAKE_ARGS+=(-DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN}")
fi

cmake "${CMAKE_ARGS[@]}"

# Build
cmake --build "${BUILDDIR}" --config Release --target build-all

echo "Done. Libraries copied to ${OUTDIR}/"
ls -la "${OUTDIR}/" 2>/dev/null || true
