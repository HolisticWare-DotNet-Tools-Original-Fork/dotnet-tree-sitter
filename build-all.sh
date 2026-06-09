#!/bin/bash

cd ./native/

# android (zig cross-compile)
source ./build-all.sh android-arm64
source ./build-all.sh android-arm
source ./build-all.sh android-x64
source ./build-all.sh android-x86

# naive build
source ./build-all.sh osx-arm64
source ./build-all.sh osx-x64
# xcompile
source ./build-all.sh linux-x64
source ./build-all.sh linux-arm64
source ./build-all.sh win-x64

cd -

tree native/out/

echo \
"file ./native/out/linux-arm64/libtree-sitter.so"
file ./native/out/linux-arm64/libtree-sitter.so

echo \
"file ./native/out/linux-x64/libtree-sitter.so"
file ./native/out/linux-x64/libtree-sitter.so

echo \
"file ./native/out/osx-arm64/libtree-sitter.dylib"
file ./native/out/osx-arm64/libtree-sitter.dylib

echo \
"file ./native/out/osx-x64/libtree-sitter.dylib"
file ./native/out/osx-x64/libtree-sitter.dylib

echo \
"file ./native/out/win-x64/tree-sitter.dll"
file ./native/out/win-x64/tree-sitter.dll

echo \
"file ./native/out/android-arm64/libtree-sitter.so"
file ./native/out/android-arm64/libtree-sitter.so

echo \
"file ./native/out/android-arm/libtree-sitter.so"
file ./native/out/android-arm/libtree-sitter.so

echo \
"file ./native/out/android-x64/libtree-sitter.so"
file ./native/out/android-x64/libtree-sitter.so

echo \
"file ./native/out/android-x86/libtree-sitter.so"
file ./native/out/android-x86/libtree-sitter.so
