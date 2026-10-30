#!/usr/bin/env bash
# Build and install Hyprland into ~/.local (run hypr-stack.sh and glslang first).
# Usage: build/hyprland.sh [version] [sha256-of-source-tarball]
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd); . "$here/env.sh"
V=${1:-0.57.0}
D=${BUILD_ROOT:-$HOME/.cache/hypr-build}/hyprland; rm -rf "$D"; mkdir -p "$D"; cd "$D"
curl -sSLO "https://github.com/hyprwm/Hyprland/releases/download/v$V/source-v$V.tar.gz"
sha256sum "source-v$V.tar.gz"   # compare with the release's published digest
[ -n "${2:-}" ] && echo "$2  source-v$V.tar.gz" | sha256sum -c -
tar xzf "source-v$V.tar.gz"; cd hyprland-source
# libc++ 20 lacks C++26 std::string::subview (one use, in a log call)
for p in "$here"/patches/hyprland-$V-*.patch; do [ -f "$p" ] && patch -p1 < "$p"; done
export CC=clang-20 CXX=clang++-20
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
  -DCMAKE_CXX_FLAGS="-stdlib=libc++" -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" -DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS" \
  -Dglslang_DIR="$HOME/.local/lib/cmake/glslang"
cmake --build build -j3   # -j3: clang++ on C++26 needs ~1.5 GB per job; 7 GB laptop
cmake --install build
