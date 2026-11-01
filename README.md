# dotfiles

Hyprland desktop on Ubuntu 24.04 with a custom [Quickshell](https://quickshell.org) shell, themed from the wallpaper
with matugen. Hyprland, Quickshell and their libraries are built from source into `~/.local` (see `build/`),
GNOME stays installed as a fallback session.

## Install

On a fresh Ubuntu 24.04 (needs `sudo` for the packages and the login-screen entry):

```sh
git clone <this repo> ~/dotfiles && cd ~/dotfiles
./install.sh            # packages, tools, build (1-2 h), links, session entry, first theme
./install.sh links      # later: only re-create the symlinks (never overwrites; backs up to ~/backups)
```

The build must not run inside Hyprland; run it from a TTY or the GNOME session. See `./install.sh --help` for the steps.

## Layout

| Path | What |
|---|---|
| `hypr/hyprland.lua` | Hyprland config (monitors, input, animations, binds, window rules) |
| `quickshell/` | the shell: bar, panels, launcher, lock screen, notifications, OSD |
| `bin/` | helper scripts, symlinked into `~/.local/bin` |
| `matugen/` | colour templates: shell, Hyprland borders, kitty |
| `pipewire/qs-eq.conf` | the 10-band equalizer (a virtual sink the shell starts) |
| `applications/` | desktop-file overrides (Spotify and VS Code on Wayland) |
| `config/` | portal config for screen sharing |
| `build/` | scripts that build the Hyprland stack and Quickshell |

Local, never committed: `~/.config/quickshell-local/calendar.ics` or `calendar-url.txt` (your calendar),
`~/.config/hypr/monitors-local.*` (display panel), `~/.local/share/screentime/`, `~/.local/share/clipboard/`.

## Keys (Super = Windows key)

| Key | Action |
|---|---|
| `Super+R` | launcher |
| `Super+Q` / `Super+C` | terminal / close window |
| `Super+B` | browser |
| `Super+W` | wallpaper carousel |
| `Super+T` | screen time |
| `Super+Y` | tools: timer / pomodoro, stopwatch, notes, calculator |
| `Super+Shift+V` | clipboard history |
| `Super+L` | lock |
| `Super+Space`, `Alt+Shift` | next keyboard layout (us, de) |
| `Super+1..9`, `Super+Shift+1..9` | workspace N on **every** monitor at once (laptop 1-10, next monitor 11-20, ...) / move the window to that monitor's workspace N |
| `Alt+Tab`, `Super+Tab` (+Shift) | window overview (grid of live previews): hold the key, Tab moves on, release picks, Del closes |
| `Super+Ctrl+Tab` (+Shift), `Super+wheel` | next / previous workspace that has windows, on every monitor |
| `Super+Arrows`, `Super+Shift+Arrows`, `Super+Ctrl+Arrows` | focus / move / resize |
| `Print`, `Shift+Print`, `Super+Print` | screenshot region / full / window (saved and copied) |
| `Super+Shift+R` | start/stop a region recording |
| `Super+Shift+T` / `Super+Shift+Q` / `Super+Shift+C` | copy text from the screen (OCR) / read a QR code / pick a colour |
| `Super+O` | workspace overview (click, 1-0, or drag a window onto a card) |
| `Super+D` | hold the dock open (it slides up when the pointer or a finger touches the bottom edge) |
| `Super+F1` | all shortcuts |
| `Super+Shift+N` | night light |
| `Super+M` | log out |

Desktop widgets (clock with weather, battery, playing track) sit on the bare desktop below all windows; switch them off in Settings > Appearance.

Bar: workspaces, media (click for the music panel), clock (calendar), weather, tray (right click for its menu),
keyboard layout (click), Wi-Fi / Bluetooth (network panel), volume (mixer), battery (power panel),
bell (notifications, right click = do not disturb).
Every panel can also be opened with `quickshell ipc call shell toggle <name>`
(`music calendar network power display screentime wallpaper clipboard launcher volume notifications`).

## Notes

* **Lock screen** unlocks with your account password (PAM stack in `quickshell/pam/`). It locks after 5 minutes idle
  and switches the screen off after 6. If it ever misbehaves: switch to a console with `Ctrl+Alt+F3`, log in and run
  `pkill quickshell; quickshell &` from a Hyprland terminal, or restart the session. `allow_session_lock_restore`
  lets a new client take over a crashed lock.
* **Modes**: `Super+Z` focus (no bar, no notifications, 25 min timer), `Super+Shift+G` game mode (no blur, no animations), `Super+P` projection
  (duplicate / extend / one screen), ``Super+` `` drop-down terminal. The bar shows a dot with the app's name while the microphone, camera or screen is in use.
* **Audio**: the mixer (`Super+Shift+…` via the bar's volume chip) also has microphone noise suppression (a virtual "Clean microphone" from PipeWire's WebRTC module, `pipewire/qs-mic.conf`) and a per-app choice of output device.
* **Launcher** (`Super+R`): maths, `5 km in mi`, `20 usd in eur` (ECB rates from frankfurter.dev), `timer 10m`, `f name` file search, `r name` recent files, `:cat` emoji.
* **GTK colours**: matugen also writes `~/.config/gtk-4.0/gtk.css` and `gtk-3.0/gtk.css`, so libadwaita apps follow the wallpaper (the global GTK theme is not touched).
* **Sleep and USB**: `bin/sleep-lock` locks the screen before any suspend (lid, idle) through a logind inhibitor; `bin/usb-mount` mounts plugged-in drives and offers Open/Eject. The coffee button in the bar stops auto-lock, screen-off and suspend.
* **Extra packages**: `sudo apt install tesseract-ocr tesseract-ocr-deu zbar-tools wvkbd` (text from the screen, QR codes, on-screen keyboard). The colour picker `hyprpicker` is built by `install.sh build`.
* **Screen sharing** needs `xdg-desktop-portal-wlr`, night light needs `wlsunset`, recording needs `wf-recorder`
  (`sudo apt install xdg-desktop-portal-wlr wlsunset wf-recorder`).
* **Blurry apps**: X11 windows are not stretched (`xwayland.force_zero_scaling`); `bin/xdpi` sets Xft.dpi from the
  monitor scale so they size themselves. Snap apps may force X11; see `applications/` for the overrides.
* Do not rebuild the stack in `~/.local` while Hyprland is running.
