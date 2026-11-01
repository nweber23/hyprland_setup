#!/usr/bin/env bash
# Set up this desktop on a fresh Ubuntu 24.04.
#
#   ./install.sh              everything: packages (sudo), build tools, the Hyprland/Quickshell build, links, fonts, theme
#   ./install.sh links        only symlink the config, scripts and desktop overrides (safe, re-runnable)
#   ./install.sh packages     only the apt packages (asks for sudo)
#   ./install.sh tools        cmake, meson, matugen and the icon font into ~/.local
#   ./install.sh build        Lua, the Hyprland stack, Hyprland and Quickshell (about 1-2 hours on a laptop)
#   ./install.sh session      register the Hyprland session in the login screen (asks for sudo)
#
# The build compiles into ~/.local and must not run while Hyprland is running; use a TTY or the GNOME session.
# Existing files are never overwritten: a different file at a link target is moved to ~/backups first.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$HOME/.local/bin" "$HOME/.local/opt" "$HOME/.config" "$HOME/backups"
export PATH="$HOME/.local/bin:$PATH"

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

# ---------- packages ----------
packages() {
    say "apt packages (sudo)"
    local runtime="grim slurp wl-clipboard brightnessctl playerctl wlsunset wf-recorder xdg-desktop-portal-wlr xdg-desktop-portal-gtk
        network-manager-gnome libnotify-bin power-profiles-daemon pipewire wireplumber pipewire-pulse jq ffmpeg mpv kitty
        python3-pil python3-venv python3-pip fonts-jetbrains-mono papirus-icon-theme curl git
        tesseract-ocr tesseract-ocr-deu zbar-tools wvkbd udisks2 keepassxc wtype"
    local build="build-essential gcc-14 g++-14 ninja-build meson pkg-config bison flex xcb-proto hwdata
        clang-20 libc++-20-dev libc++abi-20-dev glslang-tools glslang-dev libre2-dev libmuparser-dev libcanberra-dev libeis-dev
        libseat-dev libliftoff-dev libpugixml-dev libxcb-icccm4-dev libxcb-xfixes0-dev libxcb-render-util0-dev libxcb-ewmh-dev
        libxcb-composite0-dev libxcb-res0-dev libspng-dev libzip-dev librsvg2-dev libmagic-dev libtomlplusplus-dev libsystemd-dev
        libudev-dev libevdev-dev libmtdev-dev libwacom-dev libgudev-1.0-dev libxml2-dev libffi-dev libexpat1-dev libxcb-util-dev
        libxcb-cursor-dev libx11-xcb-dev libxkbregistry-dev libpolkit-agent-1-dev libjemalloc-dev libcli11-dev libpam0g-dev
        libpipewire-0.3-dev"
    # shellcheck disable=SC2086
    sudo apt-get update && sudo apt-get install -y $runtime $build
}

# ---------- tools in ~/.local ----------
tools() {
    say "cmake, meson, matugen, icon font"
    if ! cmake --version 2>/dev/null | grep -q " 4\."; then   # the Hyprland libraries need a recent cmake
        local v=4.4.5 d="$HOME/.local/opt/cmake-4.4.5-linux-x86_64"
        [ -d "$d" ] || curl -sSL "https://github.com/Kitware/CMake/releases/download/v$v/cmake-$v-linux-x86_64.tar.gz" | tar xz -C "$HOME/.local/opt"
        for b in cmake ctest cpack; do ln -sf "$d/bin/$b" "$HOME/.local/bin/$b"; done
    fi
    if ! meson --version >/dev/null 2>&1 || [ ! -d "$HOME/.local/opt/meson-venv" ]; then   # distro meson is too old for some libraries
        python3 -m venv "$HOME/.local/opt/meson-venv"
        "$HOME/.local/opt/meson-venv/bin/pip" install -q --upgrade meson
        ln -sf "$HOME/.local/opt/meson-venv/bin/meson" "$HOME/.local/bin/meson"
    fi
    if ! command -v matugen >/dev/null; then
        local v=4.2.0 d="$HOME/.local/opt/matugen-4.2.0"
        mkdir -p "$d"; curl -sSL "https://github.com/InioX/matugen/releases/download/v$v/matugen-$v-x86_64.tar.gz" | tar xz -C "$d"
        ln -sf "$(find "$d" -type f -name matugen | head -1)" "$HOME/.local/bin/matugen"
    fi
    local f="$HOME/.local/share/fonts/MaterialSymbolsRounded.ttf"
    if [ ! -f "$f" ]; then   # the shell's icons
        mkdir -p "$(dirname "$f")"
        curl -sSL -o "$f" 'https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf'
        fc-cache -f "$(dirname "$f")"
    fi
}

# ---------- build ----------
build() {
    if pgrep -x Hyprland >/dev/null; then
        echo "Hyprland is running. Building into ~/.local now would replace files it uses; log out and run './install.sh build' from a TTY or the GNOME session." >&2
        exit 1
    fi
    say "Lua, Hyprland stack, Hyprland, Quickshell"
    "$here/build/lua.sh"
    "$here/build/hypr-stack.sh"
    "$here/build/hyprland.sh"
    "$here/build/quickshell.sh"
    # colour picker (not packaged for Ubuntu 24.04)
    "$here/build/dep.sh" cmake hyprpicker https://github.com/hyprwm/hyprpicker.git v0.4.7 -DBUILD_TESTING=OFF
}

# ---------- links ----------
link() {   # link <target in the repo> <link path>
    local target=$1 path=$2
    mkdir -p "$(dirname "$path")"
    if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then return; fi
    if [ -e "$path" ] || [ -L "$path" ]; then
        mv "$path" "$HOME/backups/$(basename "$path").$(date +%F-%H%M%S)"
        echo "backed up $path to ~/backups"
    fi
    ln -s "$target" "$path"; echo "linked $path"
}
links() {
    say "links"
    # matugen's config and the equalizer refer to the repo as ~/dotfiles
    [ "$here" = "$HOME/dotfiles" ] || [ -e "$HOME/dotfiles" ] || { ln -s "$here" "$HOME/dotfiles"; echo "linked ~/dotfiles"; }
    for f in "$here"/bin/*; do link "$f" "$HOME/.local/bin/$(basename "$f")"; done
    link "$here/quickshell"                          "$HOME/.config/quickshell"
    link "$here/hypr/hyprland.lua"                   "$HOME/.config/hypr/hyprland.lua"
    link "$here/matugen/config.toml"                 "$HOME/.config/matugen/config.toml"
    link "$here/config/xdg-desktop-portal/hyprland-portals.conf" "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
    link "$here/config/xdg-desktop-portal-wlr/config" "$HOME/.config/xdg-desktop-portal-wlr/config"
    for f in "$here"/applications/*.desktop; do link "$f" "$HOME/.local/share/applications/$(basename "$f")"; done
    # kitty takes its colours from matugen's output
    local kc="$HOME/.config/kitty/kitty.conf" inc="include ~/.cache/kitty-colors.conf"
    mkdir -p "$(dirname "$kc")"; touch "$kc"
    grep -qxF "$inc" "$kc" || printf '\n%s\n' "$inc" >> "$kc"
    mkdir -p "$HOME/.config/quickshell-local" "$HOME/Pictures/Wallpapers"; chmod 700 "$HOME/.config/quickshell-local"
}

# ---------- session entry ----------
session() {
    say "login screen entry (sudo)"
    sed "s|/home/[^/]*/|$HOME/|" "$here/system/hyprland-local.desktop" | sudo tee /usr/share/wayland-sessions/hyprland-local.desktop >/dev/null
    echo "installed: pick \"Hyprland (local build)\" at the login screen"
}

# ---------- first theme ----------
theme() {
    local w; w=$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.png' -o -name '*.webp' \) 2>/dev/null | head -1)
    if [ -n "$w" ]; then say "colour theme from $w"; set-wallpaper "$w" || true
    else echo "No wallpaper in ~/Pictures/Wallpapers yet: add one, then press Super+W to choose it."; fi
}

case "${1:-all}" in
    links) links ;;
    packages) packages ;;
    tools) tools ;;
    build) build ;;
    session) session ;;
    all) packages; tools; build; links; session; theme
         say "done. Log out and pick \"Hyprland (local build)\"."
         echo "Not part of the repo: your calendar (~/.config/quickshell-local/calendar.ics or calendar-url.txt)." ;;
    *) sed -n '2,12p' "$0"; exit 1 ;;
esac
