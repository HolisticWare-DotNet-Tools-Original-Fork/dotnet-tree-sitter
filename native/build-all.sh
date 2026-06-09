#!/usr/bin/env bash
#
# Build all native tree-sitter libraries with CMake.
# Produces .so/.dylib/.dll files in native/out/{platform}/
# to match the layout expected by the .NET bindings.
#
# Usage:
#   ./native/build-all.sh osx-arm64        # macOS Apple Silicon (native)
#   ./native/build-all.sh osx-x64          # macOS Intel (native)
#   ./native/build-all.sh linux-x64        # Linux x86_64  (zig cc cross-compile)
#   ./native/build-all.sh linux-arm64      # Linux ARM64   (zig cc cross-compile)
#   ./native/build-all.sh win-x64          # Windows x86_64 (zig cc cross-compile)
#   ./native/build-all.sh android-arm64    # Android ARM64  (NDK clang)
#   ./native/build-all.sh android-arm      # Android ARMv7  (NDK clang)
#   ./native/build-all.sh android-x64      # Android x86_64 (NDK clang)
#   ./native/build-all.sh android-x86      # Android x86    (NDK clang)
#
# Linux/Windows cross-compilation requires: brew install zig
# Android requires the Android NDK (detected via ANDROID_NDK, ANDROID_NDK_HOME,
# ANDROID_SDK_ROOT, ANDROID_HOME, or ~/Library/Android/sdk on macOS).
#
# Android API level can be overridden: ANDROID_API=24 ./native/build-all.sh android-arm64
ANDROID_API="${ANDROID_API:-21}"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM="${1:-}"

if [ -z "$PLATFORM" ]; then
    echo "Usage: $0 <platform>"
    echo "Platforms: osx-arm64, osx-x64, linux-x64, linux-arm64, win-x64"
    echo "           android-arm64, android-arm, android-x64, android-x86"
    exit 1
fi

OUTDIR="${SCRIPT_DIR}/out/${PLATFORM}"
BUILDDIR="${SCRIPT_DIR}/build-cmake-${PLATFORM}"

# ZIG_TARGET: non-empty = use zig cc cross-compilation
# NDK_ARCH:   non-empty = use NDK clang (android builds)
ZIG_TARGET=""
NDK_ARCH=""
CMAKE_SYSTEM_NAME=""

case "$PLATFORM" in
    osx-arm64|osx-x64)
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
    android-arm64)
        NDK_ARCH="aarch64-linux-android"
        CMAKE_SYSTEM_NAME="Linux"
        ;;
    android-arm)
        NDK_ARCH="armv7a-linux-androideabi"
        CMAKE_SYSTEM_NAME="Linux"
        ;;
    android-x64)
        NDK_ARCH="x86_64-linux-android"
        CMAKE_SYSTEM_NAME="Linux"
        ;;
    android-x86)
        NDK_ARCH="i686-linux-android"
        CMAKE_SYSTEM_NAME="Linux"
        ;;
    *)
        echo "Unknown platform: ${PLATFORM}"
        echo "Platforms: osx-arm64, osx-x64, linux-x64, linux-arm64, win-x64"
        echo "           android-arm64, android-arm, android-x64, android-x86"
        exit 1
        ;;
esac

# Zig cross-compilation: verify zig is available
if [ -n "$ZIG_TARGET" ]; then
    if ! command -v zig &>/dev/null; then
        echo "ERROR: zig not found. Install with: brew install zig"
        exit 1
    fi
    echo 'int foo(void) { return 0; }' | zig cc -target "$ZIG_TARGET" -x c -c - -o /dev/null 2>/dev/null || {
        echo "ERROR: zig cannot compile for target: ${ZIG_TARGET}"
        exit 1
    }
    echo "Cross-compiling $PLATFORM using zig cc -target $ZIG_TARGET"
fi

# Android NDK: locate the NDK and resolve the clang wrapper
NDK_CC=""
if [ -n "$NDK_ARCH" ]; then
    NDK_ROOT=""
    if [ -d "${ANDROID_NDK:-}" ] && [ -d "${ANDROID_NDK}/toolchains" ]; then
        NDK_ROOT="${ANDROID_NDK}"
    elif [ -n "${ANDROID_NDK_HOME:-}" ]; then
        if [ -d "${ANDROID_NDK_HOME}/toolchains" ]; then
            NDK_ROOT="${ANDROID_NDK_HOME}"
        elif [ -d "${ANDROID_NDK_HOME}/ndk" ]; then
            NDK_VERSION=$(ls "${ANDROID_NDK_HOME}/ndk" | sort -V | tail -1)
            NDK_ROOT="${ANDROID_NDK_HOME}/ndk/${NDK_VERSION}"
        fi
    fi
    if [ -z "$NDK_ROOT" ]; then
        local_sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
        if [ -d "${local_sdk}/ndk" ]; then
            NDK_VERSION=$(ls "${local_sdk}/ndk" | sort -V | tail -1)
            NDK_ROOT="${local_sdk}/ndk/${NDK_VERSION}"
        fi
    fi
    if [ -z "$NDK_ROOT" ]; then
        echo "ERROR: Android NDK not found."
        echo "Set ANDROID_NDK to the NDK root, or install via Android Studio."
        exit 1
    fi

    case "$(uname -s)" in
        Darwin) NDK_HOST="darwin-x86_64" ;;
        Linux)  NDK_HOST="linux-x86_64" ;;
        *) echo "ERROR: Unsupported host OS for Android NDK build"; exit 1 ;;
    esac

    NDK_BIN="${NDK_ROOT}/toolchains/llvm/prebuilt/${NDK_HOST}/bin"
    NDK_CC="${NDK_BIN}/${NDK_ARCH}${ANDROID_API}-clang"

    if [ ! -f "$NDK_CC" ]; then
        echo "ERROR: NDK clang not found: ${NDK_CC}"
        echo "Available API levels: $(ls "${NDK_BIN}/${NDK_ARCH}"*-clang 2>/dev/null | sed 's/.*android\([0-9]*\).*/\1/' | tr '\n' ' ')"
        exit 1
    fi
    echo "Cross-compiling $PLATFORM using NDK: $(basename "$NDK_CC") (API ${ANDROID_API})"
fi

echo "Building for ${PLATFORM} -> ${OUTDIR}"

CMAKE_ARGS=(
    -S "${SCRIPT_DIR}"
    -B "${BUILDDIR}"
    -DTREE_SITTER_OUTPUT_DIR="${OUTDIR}"
    -DCMAKE_BUILD_TYPE=Release
)

if [ -n "$NDK_CC" ]; then
    CMAKE_ARGS+=(
        -DCMAKE_SYSTEM_NAME="${CMAKE_SYSTEM_NAME}"
        -DCMAKE_C_COMPILER="${NDK_CC}"
    )
    # Wipe build dir if the cached compiler differs from the NDK clang we want
    if [ -f "${BUILDDIR}/CMakeCache.txt" ]; then
        cached_cc=$(grep "^CMAKE_C_COMPILER:" "${BUILDDIR}/CMakeCache.txt" | cut -d= -f2)
        if [[ "$cached_cc" != "$NDK_CC" ]]; then
            echo "Compiler changed (was: $cached_cc) — clearing build dir"
            rm -rf "${BUILDDIR}"
        fi
    fi
    cmake "${CMAKE_ARGS[@]}"
elif [ -n "$ZIG_TARGET" ]; then
    CMAKE_ARGS+=(-DCMAKE_SYSTEM_NAME="${CMAKE_SYSTEM_NAME}")
    # Windows needs zig ar to handle COFF response files (macOS native ar fails)
    if [ "${CMAKE_SYSTEM_NAME}" = "Windows" ]; then
        CMAKE_ARGS+=(-DCMAKE_AR="${SCRIPT_DIR}/cmake/zig-ar")
    fi
    CC="zig cc -target ${ZIG_TARGET}" cmake "${CMAKE_ARGS[@]}"
else
    cmake "${CMAKE_ARGS[@]}"
fi

cmake --build "${BUILDDIR}" --config Release --target build-all

echo "Done. Libraries copied to ${OUTDIR}/"
ls -la "${OUTDIR}/" 2>/dev/null || true
