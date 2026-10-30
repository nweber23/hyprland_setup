# dotfiles

Hyprland desktop on Ubuntu 24.04 with a custom [Quickshell](https://quickshell.org) shell, themed from the wallpaper
with matugen. Hyprland, Quickshell and their libraries are built from source into `~/.local` (see `build/`),
GNOME stays installed as a fallback session. The look and the panels follow the *Serpantinum* desktop by ilyamiro
(<https://github.com/ilyamiro/serpantinum>, AGPL-3.0); this repository contains no code copied from it.

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
| `Super+Shift+V` | clipboard history |
| `Super+L` | lock |
| `Super+Space`, `Alt+Shift` | next keyboard layout (us, de) |
| `Super+1..9`, `Super+Shift+1..9` | workspace / move window there |
| `Super+Tab`, `Super+Shift+Tab` | next / previous workspace |
| `Super+Arrows`, `Super+Shift+Arrows`, `Super+Ctrl+Arrows` | focus / move / resize |
| `Print`, `Shift+Print`, `Super+Print` | screenshot region / full / window (saved and copied) |
| `Super+Shift+R` | start/stop a region recording |
| `Super+Shift+N` | night light |
| `Super+M` | log out |

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
* **Screen sharing** needs `xdg-desktop-portal-wlr`, night light needs `wlsunset`, recording needs `wf-recorder`
  (`sudo apt install xdg-desktop-portal-wlr wlsunset wf-recorder`).
* **Blurry apps**: X11 windows are not stretched (`xwayland.force_zero_scaling`); `bin/xdpi` sets Xft.dpi from the
  monitor scale so they size themselves. Snap apps may force X11; see `applications/` for the overrides.
* Do not rebuild the stack in `~/.local` while Hyprland is running.
