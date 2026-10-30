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
    property bool liveOnBattery: false   // false: an animated wallpaper pauses while on battery

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell-local/settings.json"
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text())
                if (d.lockMinutes !== undefined) root.lockMinutes = d.lockMinutes
                if (d.screenOffMinutes !== undefined) root.screenOffMinutes = d.screenOffMinutes
                if (d.popupSeconds !== undefined) root.popupSeconds = d.popupSeconds
                if (d.themeMode === "dark" || d.themeMode === "light") root.themeMode = d.themeMode
                if (d.suspendMinutes !== undefined) root.suspendMinutes = d.suspendMinutes
                if (d.autoSaver !== undefined) root.autoSaver = !!d.autoSaver
                if (d.liveOnBattery !== undefined) root.liveOnBattery = !!d.liveOnBattery
            } catch (e) { console.warn("Settings: bad settings.json:", e) }
        }
    }
    function set(key, value) {
        root[key] = value
        file.setText(JSON.stringify({ lockMinutes: lockMinutes, screenOffMinutes: screenOffMinutes, popupSeconds: popupSeconds, themeMode: themeMode, liveOnBattery: liveOnBattery, suspendMinutes: suspendMinutes, autoSaver: autoSaver }, null, 2))
    }
}
