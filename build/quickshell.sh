#!/usr/bin/env bash
# Install Qt (prebuilt, via aqtinstall) and build Quickshell against it.
# Ubuntu 24.04 ships Qt 6.4; Quickshell needs >= 6.6 and private Qt headers.
# Needs (apt): libcli11-dev libjemalloc-dev libpolkit-agent-1-dev libpam0g-dev libpipewire-0.3-dev
# Quickshell must be rebuilt whenever the Qt version changes (private-API ABI).
set -euo pipefail
QT=${1:-6.12.0} QS=${2:-v0.3.2}
python3 -m venv "$HOME/.local/opt/aqt-venv"; "$HOME/.local/opt/aqt-venv/bin/pip" install -q --upgrade aqtinstall
"$HOME/.local/opt/aqt-venv/bin/aqt" install-qt linux desktop "$QT" linux_gcc_64 -O "$HOME/.local/opt/Qt" -m qtshadertools qtmultimedia   # multimedia: animated wallpapers
Q="$HOME/.local/opt/Qt/$QT/gcc_64"; export PATH="$Q/bin:$PATH"
src="$HOME/.cache/hypr-build/quickshell"; rm -rf "$src"
git clone -q -c advice.detachedHead=false --depth 1 --branch "$QS" https://github.com/quickshell-mirror/quickshell.git "$src"
cd "$src"
# g++/libstdc++ (not libc++): Qt is built that way. Crash handler off: needs cpptrace.
CC=gcc-14 CXX=g++-14 cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
  -DCMAKE_PREFIX_PATH="$Q;$HOME/.local" -DCMAKE_INSTALL_RPATH="$Q/lib;$HOME/.local/lib" \
  -DINSTALL_QML_PREFIX=lib/qt6/qml -DCRASH_HANDLER=OFF
cmake --build build -j3
cmake --install build
