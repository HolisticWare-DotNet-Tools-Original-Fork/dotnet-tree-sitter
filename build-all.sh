#!/bin/bash

cd ./native/

# naive build
source ./build-all.sh osx-arm64
source ./build-all.sh osx-x64
# xcompile
source ./build-all.sh linux-x64
source ./build-all.sh linux-arm64
source ./build-all.sh win-x64

cd -

tree native/out/

file ./native/out/linux-arm64/libtree-sitter.so
file ./native/out/linux-x64/libtree-sitter.so
file ./native/out/win-x64/libtree-sitter.so
file ./native/out/osx-arm64/libtree-sitter.so
file ./native/out/osx-x64/libtree-sitter.so
