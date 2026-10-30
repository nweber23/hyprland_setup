pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// 10-band equalizer. Runs pipewire/qs-eq.conf as a child process (a virtual "qs_eq" sink),
// changes band gains live through pw-cli and, when enabled, makes that sink the default output.
Singleton {
    id: root
    readonly property var freqLabels: ["31", "62", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property real range: 12   // dB, +/-
    readonly property var presets: ({
        "Flat":   [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Bass":   [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
        "Vocal":  [-2, -2, -1, 1, 3, 4, 3, 1, 0, -1],
        "Treble": [0, 0, 0, 0, 0, 1, 3, 4, 5, 6],
        "Rock":   [4, 3, 1, -1, -2, 0, 2, 3, 4, 4]
    })

    property var gains: presets["Flat"]
    property string preset: "Flat"
    readonly property var node: {
        const ns = Pipewire.nodes.values
        for (let i = 0; i < ns.length; i++) if (ns[i].name === "qs_eq") return ns[i]
        return null
    }
    readonly property bool enabled: node !== null && Pipewire.preferredDefaultAudioSink === node

    function setEnabled(on) { Pipewire.preferredDefaultAudioSink = on && node ? node : null }

    function setBand(i, db) {
        const g = gains.slice()
        g[i] = Math.max(-range, Math.min(range, Math.round(db * 2) / 2))
        gains = g
        preset = "Custom"
        push.restart()
    }
    function setPreset(name) { gains = presets[name].slice(); preset = name; push.restart() }

    // Debounced: dragging a slider fires many changes, pw-cli is spawned once per pause.
    Timer {
        id: push
        interval: 60
        onTriggered: {
            root.apply()
            store.setText(JSON.stringify({ gains: root.gains, preset: root.preset }))
        }
    }
    function apply() {
        if (!node) return
        let p = ""
        for (let i = 0; i < 10; i++) p += '"eq_band_' + (i + 1) + ':Gain" ' + gains[i].toFixed(1) + " "
        Quickshell.execDetached(["pw-cli", "s", String(node.id), "Props", "{ params = [ " + p + "] }"])
    }
    // A fresh node starts flat: push the saved gains as soon as it shows up.
    onNodeChanged: if (node) apply()

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.cache/quickshell/eq.json"
        onLoaded: {
            try {
                const d = JSON.parse(text())
                if (Array.isArray(d.gains) && d.gains.length === 10) { root.gains = d.gains.map(Number); root.preset = String(d.preset) }
            } catch (e) {}
        }
    }

    // Clears a leftover engine from a previous run. The pattern is anchored so it cannot match this sh itself.
    Process {
        running: true
        command: ["sh", "-c", "pkill -f '^(/usr/bin/)?pipewire -c .*qs-eq\\.conf$'; exec pipewire -c \"$HOME/dotfiles/pipewire/qs-eq.conf\""]
    }
}
