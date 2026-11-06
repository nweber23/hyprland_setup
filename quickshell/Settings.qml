pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// User settings that the shell itself uses, kept in ~/.config/quickshell-local/settings.json (not in the repo).
Singleton {
    id: root
    property int lockMinutes: 5          // lock after this many idle minutes, 0 = never
    property int screenOffMinutes: 6     // screen off while locked and idle, 0 = never
    property int popupSeconds: 6         // how long notification popups stay
    property string themeMode: "dark"    // "dark" | "light", applied by matugen
    property int suspendMinutes: 15      // suspend after this many idle minutes on battery, 0 = never
    property bool autoSaver: true        // switch to the power-saver profile at 20 % and below
    property bool dock: true             // app dock at the bottom edge
    property bool widgets: true          // clock, battery and music on the bare desktop
    property bool visualizer: true       // the music widget shows live audio bars while something plays
    property string wallpaperEffect: "circle"   // how a new wallpaper arrives: circle | fade | wipe | zoom | random
    property bool clickEffect: false     // a ring at every left click (for screen recordings)
    property string barPosition: "top"   // "top" | "bottom"
    property bool barAutohide: false     // the bar slides away and comes back when the pointer touches the screen edge
    property var barHidden: []           // bar modules that are switched off: search bell workspaces media clock weather tray status
    property var dockApps: [             // the app dock: name, desktop id, window class, icon
        { name: "Spotify", id: "spotify_spotify", cls: "spotify", icon: "spotify" },
        { name: "Chrome", id: "google-chrome", cls: "google-chrome", icon: "google-chrome" },
        { name: "Discord", id: "discord_discord", cls: "discord", icon: "discord" },
        { name: "VS Code", id: "com.microsoft.VSCode", cls: "com.microsoft.VSCode", icon: "vscode" }
    ]
    onClickEffectChanged: Quickshell.execDetached(["sh", "-c", 'mkdir -p "$HOME/.cache/quickshell"; echo "$1" > "$HOME/.cache/quickshell/ripple.txt"', "sh", clickEffect ? "1" : "0"])   // read by the click bind in hyprland.lua
    property var widgetLayout: ({})      // where the desktop widgets were dragged to: { "<screen>:<widget>": { x, y, s } }
    property var mutedApps: []           // notifications from these apps skip the pop-up but stay in the history
    property bool noiseSuppression: false // the "Clean microphone" is the default microphone
    property bool liveOnBattery: false   // false: an animated wallpaper pauses while on battery
    // pointer and keyboard (applied to Hyprland by the settings panel, which also writes input-local.lua)
    property bool naturalScroll: false   // touchpad: content follows the fingers
    property bool tapToClick: true       // touchpad: tapping clicks
    property bool disableTyping: true    // touchpad: ignored while typing
    property real pointerSpeed: 0        // -1 .. 1, mouse and touchpad
    property real scrollSpeed: 1         // touchpad scrolling factor
    property string accelProfile: "adaptive"   // "adaptive" | "flat"
    property int repeatRate: 25          // key repeats per second
    property int repeatDelay: 600        // ms before a held key repeats

    readonly property var keys: ["lockMinutes", "screenOffMinutes", "popupSeconds", "themeMode", "suspendMinutes", "autoSaver", "dock", "widgets", "visualizer", "wallpaperEffect", "clickEffect", "barPosition", "barAutohide", "barHidden", "dockApps", "widgetLayout",
                                 "liveOnBattery", "noiseSuppression", "mutedApps", "naturalScroll", "tapToClick", "disableTyping", "pointerSpeed", "scrollSpeed", "accelProfile",
                                 "repeatRate", "repeatDelay"]
    readonly property var allowed: ({ themeMode: ["dark", "light"], accelProfile: ["adaptive", "flat"], wallpaperEffect: ["circle", "fade", "wipe", "zoom", "random"], barPosition: ["top", "bottom"] })


    // Lists are checked item by item, so a damaged file cannot put wrong data into the shell:
    // plain lists hold text, the dock holds { name, id, cls, icon }, the widget layout holds { x, y, s } per widget.
    function clean(key, v) {
        if (key === "dockApps")
            return v.filter(a => a && typeof a.name === "string" && typeof a.id === "string" && typeof a.cls === "string" && typeof a.icon === "string")
        if (key === "widgetLayout") {
            const out = {}
            for (const n in v) if (v[n] && typeof v[n].x === "number" && typeof v[n].y === "number") out[n] = { x: v[n].x, y: v[n].y, s: typeof v[n].s === "number" ? v[n].s : 1 }
            return out
        }
        return Array.isArray(v) ? v.filter(x => typeof x === "string") : v
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell-local/settings.json"
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text())
                for (const k of root.keys) {
                    if (d[k] === undefined || typeof d[k] !== typeof root[k] || Array.isArray(d[k]) !== Array.isArray(root[k])) continue   // unknown or wrongly typed: keep the default
                    if (root.allowed[k] && root.allowed[k].indexOf(d[k]) < 0) continue
                    root[k] = root.clean(k, d[k])
                }
            } catch (e) { console.warn("Settings: bad settings.json:", e) }
        }
    }
    function set(key, value) {
        root[key] = value
        const out = {}
        for (const k of root.keys) out[k] = root[k]
        file.setText(JSON.stringify(out, null, 2))
    }
}
