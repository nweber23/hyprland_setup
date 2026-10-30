#!/usr/bin/env bash
# Build one dependency from a git tag into ~/.local.
# Usage: build/dep.sh meson|cmake <name> <git-url> <tag> [extra configure args...]
set -euo pipefail
. "$(dirname "$0")/env.sh"
kind=$1 name=$2 url=$3 tag=$4; shift 4
src=${BUILD_ROOT:-$HOME/.cache/hypr-build}/$name
rm -rf "$src"; mkdir -p "$(dirname "$src")"
git clone -q -c advice.detachedHead=false --depth 1 --branch "$tag" "$url" "$src"
cd "$src"
case $kind in
  meson) meson setup build --prefix="$HOME/.local" --libdir=lib --buildtype=release "$@"
         ninja -C build; ninja -C build install ;;
  cmake) export CC=clang-20 CXX=clang++-20
         cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
               -DCMAKE_CXX_FLAGS="-stdlib=libc++" -DCMAKE_EXE_LINKER_FLAGS="-stdlib=libc++ $LDFLAGS" \
               -DCMAKE_SHARED_LINKER_FLAGS="-stdlib=libc++ $LDFLAGS" "$@"
         cmake --build build; cmake --install build ;;
esac
echo "installed $name $tag"
