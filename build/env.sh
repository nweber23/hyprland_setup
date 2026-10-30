# Source before building anything for the Hyprland stack: `. build/env.sh`
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$HOME/.local/share/pkgconfig:$HOME/.local/lib/x86_64-linux-gnu/pkgconfig"
export LD_LIBRARY_PATH="$HOME/.local/lib:$HOME/.local/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CMAKE_PREFIX_PATH="$HOME/.local"
# Bake an rpath into everything built here so it finds ~/.local/lib without LD_LIBRARY_PATH.
export LDFLAGS="-Wl,-rpath,$HOME/.local/lib -Wl,-rpath,$HOME/.local/lib/x86_64-linux-gnu${LDFLAGS:+ $LDFLAGS}"
