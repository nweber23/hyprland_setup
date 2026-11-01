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

    readonly property var keys: ["lockMinutes", "screenOffMinutes", "popupSeconds", "themeMode", "suspendMinutes", "autoSaver", "dock", "widgets",
                                 "liveOnBattery", "naturalScroll", "tapToClick", "disableTyping", "pointerSpeed", "scrollSpeed", "accelProfile",
                                 "repeatRate", "repeatDelay"]
    readonly property var allowed: ({ themeMode: ["dark", "light"], accelProfile: ["adaptive", "flat"] })


    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell-local/settings.json"
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text())
                for (const k of root.keys) {
                    if (d[k] === undefined || typeof d[k] !== typeof root[k]) continue   // unknown or wrongly typed: keep the default
                    if (root.allowed[k] && root.allowed[k].indexOf(d[k]) < 0) continue
                    root[k] = d[k]
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
