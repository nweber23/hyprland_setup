pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// The output whose volume the user controls: the real device, also while the equalizer sits in front of it.
Singleton {
    id: root
    readonly property var sink: {
        const d = Pipewire.defaultAudioSink
        return d && d.name === "qs_eq" && Eq.hardware ? Eq.hardware : d
    }
    PwObjectTracker { objects: [root.sink] }
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    function setVolume(v) { if (sink && sink.audio) sink.audio.volume = Math.max(0, v) }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted }
    // choosing another real output ends the equalizer (it plays into one fixed device)
    function pick(node) { if (Eq.enabled) Eq.setEnabled(false); Pipewire.preferredDefaultAudioSink = node }
}
