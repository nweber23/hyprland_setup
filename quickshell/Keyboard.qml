pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Active keyboard layout, kept current from Hyprland's activelayout event (no polling).
Singleton {
    id: root
    property string name: ""          // e.g. "German"
    property string layout: "--"      // short code for the bar, e.g. "DE"
    property int count: 1             // how many layouts are configured
    property int index: 0             // active layout index of the main keyboard

    function short(n) {
        const known = { "English (US)": "EN", "English": "EN", "German": "DE", "French": "FR", "Spanish": "ES", "Italian": "IT", "Polish": "PL", "Russian": "RU" }
        return known[n] ?? n.replace(/\(.*\)/, "").trim().slice(0, 2).toUpperCase()
    }
    function cycle() { Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", String((index + 1) % Math.max(1, count))]) }

    function refresh() { q.running = true }
    Process {
        id: q
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards
                    const main = kbs.find(k => k.main) ?? kbs[0]
                    root.name = main.active_keymap.replace(/ \(.*\)/, "") === "English" ? "English (US)" : main.active_keymap
                    root.layout = root.short(main.active_keymap)
                    root.count = main.layout.split(",").length
                    root.index = main.active_layout_index
                    // every keyboard follows the main one, otherwise an external keyboard can sit on another layout than the bar shows
                    if (kbs.some(k => k.active_layout_index !== main.active_layout_index))
                        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", String(main.active_layout_index)])
                } catch (e) {}
            }
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (e.name === "activelayout") root.refresh()   // the event names whichever keyboard changed, not necessarily the main one
        }
    }
}
