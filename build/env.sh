# Source before building anything for the Hyprland stack: `. build/env.sh`
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$HOME/.local/share/pkgconfig:$HOME/.local/lib/x86_64-linux-gnu/pkgconfig"
export LD_LIBRARY_PATH="$HOME/.local/lib:$HOME/.local/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CMAKE_PREFIX_PATH="$HOME/.local"
