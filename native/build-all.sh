#!/bin/sh
#
# Build all native tree-sitter libraries with CMake.
# Produces .so/.dylib/.dll files in native/out/{platform}/
# to match the layout expected by the .NET bindings.
#
# Usage:
#   ./native/build-all.sh osx-arm64        # macOS Apple Silicon
#   ./native/build-all.sh osx-x64          # macOS Intel
#   ./native/build-all.sh linux-x64        # Linux x86_64
#   ./native/build-all.sh linux-arm64      # Linux ARM64
#   ./native/build-all.sh win-x64          # Windows x86_64 (requires Visual Studio)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLATFORM="${1:-}"

if [ -z "$PLATFORM" ]; then
    echo "Usage: $0 <platform>"
    echo "Platforms: osx-arm64, osx-x64, linux-x64, linux-arm64, win-x64"
    exit 1
fi

OUTDIR="${SCRIPT_DIR}/out/${PLATFORM}"
BUILDDIR="${SCRIPT_DIR}/build-cmake"

echo "Building for ${PLATFORM} -> ${OUTDIR}"

# Configure
cmake -S "${SCRIPT_DIR}" \
      -B "${BUILDDIR}" \
      -DTREE_SITTER_OUTPUT_DIR="${OUTDIR}" \
      -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build "${BUILDDIR}" --config Release --target build-all

echo "Done. Libraries copied to ${OUTDIR}/"
ls -la "${OUTDIR}/" 2>/dev/null || true
