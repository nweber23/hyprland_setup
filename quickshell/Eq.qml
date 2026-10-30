pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// 10-band equalizer. Runs pipewire/qs-eq.conf as a child process (a virtual "qs_eq" sink),
// changes band gains live through pw-cli and, when enabled, makes that sink the default output.
Singleton {
    id: root
    // Test instances (QS_TEST=1) must not start or kill the equalizer engine or touch any volume.
    readonly property bool testMode: !!Quickshell.env("QS_TEST")
    readonly property var freqLabels: ["31", "62", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property real range: 12   // dB, +/-
    readonly property var presets: ({
        "Flat":    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Bass":    [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
        "Treble":  [0, 0, 0, 0, 0, 1, 3, 4, 5, 6],
        "Vocal":   [-2, -2, -1, 1, 3, 4, 3, 1, 0, -1],
        "Pop":     [-1, 1, 3, 4, 3, 0, -1, -1, 1, 2],
        "Rock":    [4, 3, 1, -1, -2, 0, 2, 3, 4, 4],
        "Jazz":    [3, 2, 1, 2, -2, -2, 0, 1, 2, 3],
        "Classic": [0, 0, 0, 0, 0, 0, -2, -2, -2, -3]
    })
    readonly property var presetOrder: ["Flat", "Bass", "Treble", "Vocal", "Pop", "Rock", "Jazz", "Classic"]

    property var gains: presets["Flat"]
    property string preset: "Flat"
    readonly property var node: {
        const ns = Pipewire.nodes.values
        for (let i = 0; i < ns.length; i++) if (ns[i].name === "qs_eq") return ns[i]
        return null
    }
    readonly property bool enabled: node !== null && Pipewire.defaultAudioSink === node

    // ---- one volume, whether the equalizer is on or not ----
    // The real output (speakers, headphones) always carries the volume. The equalizer node stays at 100% and
    // never shows up as a device; whatever sets its volume or mute (keys, wpctl, an app) is handed to the real output.
    property string hwName: ""                       // name of the real output the equalizer plays into
    readonly property var hardware: {
        const ns = Pipewire.nodes.values
        return ns.find(n => n.name === hwName && n.audio) ?? ns.find(n => n.isSink && !n.isStream && n.name !== "qs_eq" && n.audio) ?? null
    }
    PwObjectTracker { objects: [root.node, root.hardware] }
    FileView { id: hwFile; path: Quickshell.env("HOME") + "/.cache/quickshell/eq-hw-id"; printErrors: false }
    onHardwareChanged: if (hardware && hwFile.path !== "") hwFile.setText(String(hardware.id))
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() { const d = Pipewire.defaultAudioSink; if (d && d.name !== "qs_eq") root.hwName = d.name }
    }
    Component.onCompleted: { const d = Pipewire.defaultAudioSink; if (d && d.name !== "qs_eq") hwName = d.name }
    // A freshly created equalizer node reports volume 0 for a moment: that is not a wish of the user, so nothing is
    // handed over in its first two seconds (it is set to 100% instead).
    property double born: 0
    function handOver() {
        const n = root.node, h = root.hardware
        if (testMode || !n || !n.audio || !h || !h.audio || !enabled) return
        if (Date.now() - born < 2000) { if (n.audio.volume !== 1) n.audio.volume = 1; return }
        // exactly 0 is what a node that is being torn down reports, not a wish; the keys go through bin/volume anyway
        if (n.audio.volume > 0 && Math.abs(n.audio.volume - 1) > 0.002) { h.audio.volume = n.audio.volume; n.audio.volume = 1 }
        if (n.audio.muted !== h.audio.muted) h.audio.muted = n.audio.muted     // mute: the two always agree
    }
    Connections { target: root.node && root.node.audio ? root.node.audio : null; function onVolumeChanged() { root.handOver() } function onMutedChanged() { root.handOver() } }
    // ... and the other way round, so toggling mute on either one flips the real output
    Connections {
        target: root.hardware && root.hardware.audio ? root.hardware.audio : null
        function onMutedChanged() { const n = root.node; if (root.enabled && n && n.audio && n.audio.muted !== root.hardware.audio.muted) n.audio.muted = root.hardware.audio.muted }
    }
    onEnabledChanged: if (enabled) handOver()

    function setEnabled(on) {
        if (on && node) {
            const d = Pipewire.defaultAudioSink
            if (d && d !== node) hwName = d.name
            if (node.ready && node.audio) { node.audio.volume = 1; node.audio.muted = hardware && hardware.audio ? hardware.audio.muted : false }   // the volume stays on the real output
            Pipewire.preferredDefaultAudioSink = node
        } else {
            Pipewire.preferredDefaultAudioSink = hardware
        }
    }

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
    // A fresh node starts flat: push the saved gains as soon as it shows up, and set it to 100% (see handOver).
    onNodeChanged: { born = Date.now(); pin.restart(); if (node) apply() }
    // set up once the node is bound (setting it earlier is an error), and keep the id of the real output for bin/volume
    Timer { id: pin; interval: 500; running: !root.testMode
        onTriggered: { if (root.node && root.node.ready && root.node.audio) root.node.audio.volume = 1; if (root.hardware) hwFile.setText(String(root.hardware.id)) } }

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
        id: engine
        running: !root.testMode
        command: ["sh", "-c", "pkill -f '^(/usr/bin/)?pipewire -c .*qs-eq\\.conf$'; exec pipewire -c \"$HOME/dotfiles/pipewire/qs-eq.conf\""]
        onRunningChanged: if (!running && !root.testMode) respawn.start()
    }
    Timer { id: respawn; interval: 1500; onTriggered: engine.running = true }   // the engine comes back if it dies
}
