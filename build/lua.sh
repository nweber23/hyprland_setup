#!/usr/bin/env bash
# Build Lua into ~/.local. Hyprland needs Lua 5.5, which Ubuntu 24.04 does not package.
# Usage: build/lua.sh [version]   (checksum: compare with https://www.lua.org/ftp/)
set -euo pipefail
V=${1:-5.5.1}
D=$(mktemp -d); cd "$D"
curl -sSLO "https://www.lua.org/ftp/lua-$V.tar.gz"
sha256sum "lua-$V.tar.gz"
tar xzf "lua-$V.tar.gz"; cd "lua-$V"
make -j"$(nproc)" linux-readline MYCFLAGS=-fPIC
make install INSTALL_TOP="$HOME/.local"
mkdir -p "$HOME/.local/lib/pkgconfig"
# `make pc` only emits the variable lines; the rest is written by hand.
cat > "$HOME/.local/lib/pkgconfig/lua5.5.pc" <<PC
prefix=$HOME/.local
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: Lua
Description: Lua language engine
Version: $V
Libs: -L\${libdir} -llua -lm -ldl
Cflags: -I\${includedir}
PC
cp "$HOME/.local/lib/pkgconfig/lua5.5.pc" "$HOME/.local/lib/pkgconfig/lua.pc"
