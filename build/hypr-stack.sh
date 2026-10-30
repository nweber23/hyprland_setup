#!/usr/bin/env bash
# Build the whole Hyprland stack into ~/.local, in dependency order.
# C++ parts use clang-20 + libc++ (Ubuntu 24.04's libstdc++ 14 lacks C++23 vector::append_range),
# so distro C++ libraries that Hyprland links (tomlplusplus, pugixml, muparser, re2/abseil) are rebuilt too.
# Plain-C libraries (wayland, libinput, xkbcommon, ...) are independent of the C++ stdlib.
set -euo pipefail
cd "$(dirname "$0")"
FD=https://gitlab.freedesktop.org H=https://github.com/hyprwm
# Usage: hypr-stack.sh [first-step-name]  -- resume from a step after a failure
skip=${1:-}
step() { # step <kind> <name> ...
  if [ -n "$skip" ]; then [ "$2" = "$skip" ] && skip= || return 0; fi
  ./dep.sh "$@"
}
# --- C libraries (newer than noble ships) ---
step meson wayland $FD/wayland/wayland.git 1.26.0 -Ddocumentation=false -Dtests=false -Ddtd_validation=false
step meson wayland-protocols $FD/wayland/wayland-protocols.git 1.50 -Dtests=false
step meson libxkbcommon https://github.com/xkbcommon/libxkbcommon.git xkbcommon-1.13.2 -Denable-docs=false -Denable-x11=false -Denable-bash-completion=false
step meson libinput $FD/libinput/libinput.git 1.32.0 -Ddocumentation=false -Dtests=false -Ddebug-gui=false
step meson libdisplay-info $FD/emersion/libdisplay-info.git 0.4.0
# --- C++ libraries rebuilt against libc++ ---
CXX=clang++-20 CXXFLAGS=-stdlib=libc++ LDFLAGS="-stdlib=libc++ ${LDFLAGS:-}" step meson tomlplusplus https://github.com/marzer/tomlplusplus.git v3.4.0 -Dgenerate_cmake_config=false  # meson defaults to g++; force libc++ like the rest of the C++ stack
step cmake pugixml https://github.com/zeux/pugixml.git v1.16 -DBUILD_SHARED_LIBS=ON
step cmake muparser https://github.com/beltoforion/muparser.git v2.3.5 -DBUILD_SHARED_LIBS=ON -DENABLE_SAMPLES=OFF -DENABLE_OPENMP=OFF
step cmake abseil-cpp https://github.com/abseil/abseil-cpp.git 20260817.0 -DBUILD_SHARED_LIBS=ON -DABSL_PROPAGATE_CXX_STD=ON -DABSL_BUILD_TESTING=OFF -DCMAKE_CXX_STANDARD=17
step cmake re2 https://github.com/google/re2.git 2025-11-05 -DBUILD_SHARED_LIBS=ON -DRE2_BUILD_TESTING=OFF
# re2.pc lists ~16 absl_* modules; this pkg-config (1.8.1) takes seconds per query and Hyprland's
# combined query then effectively hangs. re2/abseil are shared libs, so Requires: is not needed to link.
sed -i '/^Requires:/d' "$HOME/.local/lib/pkgconfig/re2.pc"
step cmake sdbus-cpp https://github.com/Kistler-Group/sdbus-cpp.git v2.3.1 -DSDBUSCPP_BUILD_DOCS=OFF -DSDBUSCPP_BUILD_TESTS=OFF -DSDBUSCPP_BUILD_CODEGEN=OFF
# glslang from the distro is libstdc++-built; Hyprland links it, so rebuild with libc++
step cmake glslang https://github.com/KhronosGroup/glslang.git 16.6.0 -DENABLE_OPT=OFF -DENABLE_GLSLANG_BINARIES=OFF -DBUILD_TESTING=OFF -DALLOW_EXTERNAL_SPIRV_TOOLS=OFF
# --- Hyprland libraries ---
step cmake hyprutils $H/hyprutils.git v0.14.3 -DBUILD_TESTING=OFF
step cmake hyprwayland-scanner $H/hyprwayland-scanner.git v0.4.6
step cmake hyprland-protocols $H/hyprland-protocols.git v0.8.0
step cmake hyprlang $H/hyprlang.git v0.6.8 -DBUILD_TESTING=OFF
step cmake hyprgraphics $H/hyprgraphics.git v0.5.1 -DBUILD_TESTING=OFF
step cmake hyprcursor $H/hyprcursor.git v0.1.13 -DBUILD_TESTING=OFF
step cmake hyprwire $H/hyprwire.git v0.3.1 -DBUILD_TESTING=OFF
step cmake aquamarine $H/aquamarine.git v0.15.1 -DBUILD_TESTING=OFF
# --- GUI helpers (hyprland-dialog, welcome, update screen); silences Hyprland's "guiutils missing" warning ---
step cmake iniparser https://github.com/ndevilla/iniparser.git v4.3.2 -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOCS=OFF
# hyprtoolkit 0.6.0 needs Pango >= 1.56 (glib 2.88, harfbuzz 11, ...); 0.5.4 is the newest that builds on noble
step cmake hyprtoolkit $H/hyprtoolkit.git v0.5.4 -DBUILD_TESTING=OFF
step cmake hyprland-guiutils $H/hyprland-guiutils.git v0.2.2
