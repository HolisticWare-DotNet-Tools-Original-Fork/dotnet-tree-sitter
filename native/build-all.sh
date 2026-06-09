#!/usr/bin/env bash
#
# Build all native tree-sitter libraries with CMake + Zig cross-compiler.
# Produces .so/.dylib/.dll files in native/out/{platform}/
# to match the layout expected by the .NET bindings.
#
# Usage:
#   ./native/build-all.sh osx-arm64        # macOS Apple Silicon (native)
#   ./native/build-all.sh osx-x64          # macOS Intel (native)
#   ./native/build-all.sh linux-x64        # Linux x86_64
#   ./native/build-all.sh linux-arm64      # Linux ARM64
#   ./native/build-all.sh win-x64          # Windows x86_64
#
# macOS builds use the system compiler. Linux/Windows builds use zig cc
# for cross-compilation (requires: brew install zig on macOS).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_DIR="${SCRIPT_DIR}/cmake"
PLATFORM="${1:-}"

if [ -z "$PLATFORM" ]; then
    echo "Usage: $0 <platform>"
    echo "Platforms: osx-arm64, osx-x64, linux-x64, linux-arm64, win-x64"
    exit 1
fi

OUTDIR="${SCRIPT_DIR}/out/${PLATFORM}"
BUILDDIR="${SCRIPT_DIR}/build-cmake-${PLATFORM}"

# Map platform to zig target triple and cmake system name
case "$PLATFORM" in
    osx-arm64|osx-x64)
        ZIG_TARGET=""
        CMAKE_SYSTEM_NAME=""
        ;;
    linux-x64)
        ZIG_TARGET="x86_64-linux-gnu"
        CMAKE_SYSTEM_NAME="Linux"
        ;;
    linux-arm64)
        ZIG_TARGET="aarch64-linux-gnu"
        CMAKE_SYSTEM_NAME="Linux"
        ;;
    win-x64)
        ZIG_TARGET="x86_64-windows-gnu"
        CMAKE_SYSTEM_NAME="Windows"
        ;;
    *)
        echo "Unknown platform: ${PLATFORM}"
        echo "Platforms: osx-arm64, osx-x64, linux-x64, linux-arm64, win-x64"
        exit 1
        ;;
esac

# For cross-compilation targets, verify zig is available
if [ -n "$ZIG_TARGET" ]; then
    if ! command -v zig &>/dev/null; then
        echo "ERROR: zig not found. Install with:"
        echo "  brew install zig (macOS)"
        exit 1
    fi
    
    # Verify zig can compile for this target
    echo 'int foo(void) { return 0; }' | zig cc -target "$ZIG_TARGET" -x c -c - -o /dev/null 2>/dev/null || {
        echo "ERROR: zig cannot compile for target: ${ZIG_TARGET}"
        exit 1
    }
    
    echo "Cross-compiling $PLATFORM using zig cc -target $ZIG_TARGET"
fi

echo "Building for ${PLATFORM} -> ${OUTDIR}"

# Configure
CMAKE_ARGS=(
    -S "${SCRIPT_DIR}"
    -B "${BUILDDIR}"
    -DTREE_SITTER_OUTPUT_DIR="${OUTDIR}"
    -DCMAKE_BUILD_TYPE=Release
)

# Cross-compilation: use CC env var with zig cc target triple.
# For Windows, also set CMAKE_AR to zig ar which handles COFF response files
# (macOS native ar fails when cross-compiling to Windows).
if [ -n "$ZIG_TARGET" ]; then
    CMAKE_ARGS+=(
        -DCMAKE_SYSTEM_NAME="${CMAKE_SYSTEM_NAME}"
    )
    if [ "${CMAKE_SYSTEM_NAME}" = "Windows" ]; then
        CC="zig cc -target ${ZIG_TARGET}" cmake -DCMAKE_AR="${SCRIPT_DIR}/cmake/zig-ar" "${CMAKE_ARGS[@]}"
    else
        CC="zig cc -target ${ZIG_TARGET}" cmake "${CMAKE_ARGS[@]}"
    fi
else
    cmake "${CMAKE_ARGS[@]}"
fi

# Build
cmake --build "${BUILDDIR}" --config Release --target build-all

echo "Done. Libraries copied to ${OUTDIR}/"
ls -la "${OUTDIR}/" 2>/dev/null || true
