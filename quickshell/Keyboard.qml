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

    function short(n) {
        const known = { "English (US)": "EN", "English": "EN", "German": "DE", "French": "FR", "Spanish": "ES", "Italian": "IT", "Polish": "PL", "Russian": "RU" }
        return known[n] ?? n.replace(/\(.*\)/, "").trim().slice(0, 2).toUpperCase()
    }
    function cycle() { Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]) }

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
                } catch (e) {}
            }
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (e.name !== "activelayout") return
            root.name = e.data.split(",").slice(1).join(",")       // "keyboard-name,Layout Name"
            root.layout = root.short(root.name)
        }
    }
}
