pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// Noise suppression for the microphone: a virtual source "Clean microphone" (WebRTC noise suppression, pipewire/qs-mic.conf)
// that runs as its own PipeWire process, like the equalizer. While it is on it is the default microphone; turning it off
// stops the process and puts the real microphone back as default.
Singleton {
    id: root
    readonly property bool enabled: Settings.noiseSuppression
    property string hwName: ""                       // node name of the real microphone, kept while the clean one is the default
    readonly property var clean: Pipewire.nodes.values.find(n => n.name === "qs_mic") ?? null

    function init() {}   // referencing the singleton is what starts it

    function set(on) {
        Settings.set("noiseSuppression", on)
        if (on) start(); else stop()
    }
    function realSource() {
        const d = Pipewire.defaultAudioSource
        if (d && d.name !== "qs_mic") return d
        return Pipewire.nodes.values.find(n => !n.isSink && !n.isStream && n.audio && !n.name.endsWith(".monitor") && n.name !== "qs_mic") ?? null
    }
    function start() {
        const s = realSource()
        if (!s || !/^[A-Za-z0-9_.:-]+$/.test(s.name)) return   // the name goes into a config file: plain characters only
        hwName = s.name
        engine.command = ["sh", "-c", 'sed "s|@TARGET@|$1|" "$HOME/dotfiles/pipewire/qs-mic.conf" > "$HOME/.cache/quickshell/qs-mic.conf" '
                          + '&& exec pipewire -c "$HOME/.cache/quickshell/qs-mic.conf"', "sh", s.name]
        engine.running = true
    }
    function stop() {
        engine.running = false
        const hw = Pipewire.nodes.values.find(n => n.name === hwName)
        if (hw) Pipewire.preferredDefaultAudioSource = hw
    }
    Process { id: engine; onRunningChanged: if (!running && root.enabled) respawn.restart() }
    Timer { id: respawn; interval: 2500; onTriggered: if (root.enabled && !engine.running) root.start() }

    PwObjectTracker { objects: Pipewire.nodes.values }
    // once the clean source exists, make it the default microphone
    onCleanChanged: if (clean && enabled && Pipewire.defaultAudioSource !== clean) Pipewire.preferredDefaultAudioSource = clean
    Component.onCompleted: if (enabled) startLater.start()
    Timer { id: startLater; interval: 4000; onTriggered: root.start() }   // PipeWire's node list needs a moment at login
}
