import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// Audio mixer: choose the output and input device, set their levels, and set the level of every app that plays sound.
Panel {
    id: root
    name: "volume"
    panelWidth: 440

    // everything that has volume controls; the tracker makes node.audio available
    readonly property var all: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var sinks: all.filter(n => n.isSink && !n.isStream)
    readonly property var sources: all.filter(n => !n.isSink && !n.isStream && !n.name.endsWith(".monitor"))
    // the equalizer's own playback stream is plumbing, not an app
    readonly property var streams: all.filter(n => n.isSink && n.isStream && !n.name.startsWith("qs_eq"))
    PwObjectTracker { objects: root.all }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function label(n) { return n.nickname !== "" ? n.nickname : (n.description !== "" ? n.description : n.name) }
    function appName(n) { return n.properties["application.name"] ?? n.properties["media.name"] ?? n.name }
    function pct(v) { return Math.round(v * 100) + "%" }

    // ---- output ----
    Reveal {
        p: root; index: 0; dy: 10
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            Icon { name: root.sink && root.sink.audio && root.sink.audio.muted ? "volume_off" : "volume_up"; size: 22; color: Theme.accent
                   MouseArea { anchors.fill: parent; onClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted } }
            Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: root.sink ? root.label(root.sink) : "No output"
                   color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
            Text { textFormat: Text.PlainText; text: root.sink && root.sink.audio ? root.pct(root.sink.audio.volume) : "--"
                   color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
        }
        MSlider { Layout.fillWidth: true; knob: true; fill: Theme.accent
                  value: root.sink && root.sink.audio ? Math.min(1, root.sink.audio.volume) : 0
                  onMoved: v => { if (root.sink && root.sink.audio) root.sink.audio.volume = v } }
        Flow {
            Layout.fillWidth: true; spacing: 6
            Repeater {
                model: root.sinks
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: root.sink === modelData
                    height: 28; width: nm.implicitWidth + 22; radius: 9
                    color: on ? Theme.accent : (ma.containsMouse ? Theme.cardHigh : Theme.card)
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Text { id: nm; anchors.centerIn: parent; textFormat: Text.PlainText; text: root.label(modelData)
                           color: parent.on ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 10; font.bold: true }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: Pipewire.preferredDefaultAudioSink = modelData }
                }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardHigh }

    // ---- input ----
    Reveal {
        p: root; index: 1; dy: 10
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            Icon { name: root.source && root.source.audio && root.source.audio.muted ? "mic_off" : "mic"; size: 22; color: Theme.accent2
                   MouseArea { anchors.fill: parent; onClicked: if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted } }
            Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: root.source ? root.label(root.source) : "No input"
                   color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
            Text { textFormat: Text.PlainText; text: root.source && root.source.audio ? root.pct(root.source.audio.volume) : "--"
                   color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
        }
        MSlider { Layout.fillWidth: true; knob: true; fill: Theme.accent2
                  value: root.source && root.source.audio ? Math.min(1, root.source.audio.volume) : 0
                  onMoved: v => { if (root.source && root.source.audio) root.source.audio.volume = v } }
        Flow {
            Layout.fillWidth: true; spacing: 6; visible: root.sources.length > 1
            Repeater {
                model: root.sources
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: root.source === modelData
                    height: 28; width: nm2.implicitWidth + 22; radius: 9
                    color: on ? Theme.accent2 : (ma2.containsMouse ? Theme.cardHigh : Theme.card)
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Text { id: nm2; anchors.centerIn: parent; textFormat: Text.PlainText; text: root.label(modelData)
                           color: parent.on ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 10; font.bold: true }
                    MouseArea { id: ma2; anchors.fill: parent; hoverEnabled: true; onClicked: Pipewire.preferredDefaultAudioSource = modelData }
                }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardHigh }

    // ---- apps ----
    Reveal {
        p: root; index: 2; dy: 10
        Text { textFormat: Text.PlainText; text: "Applications"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
        Text { visible: root.streams.length === 0; textFormat: Text.PlainText; text: "Nothing is playing"; color: Theme.outline; font.family: Theme.mono; font.pixelSize: 12 }
        Repeater {
            model: root.streams
            delegate: ColumnLayout {
                id: app
                required property var modelData
                Layout.fillWidth: true; spacing: 4
                RowLayout {
                    spacing: 10
                    Image { Layout.preferredWidth: 18; Layout.preferredHeight: 18; sourceSize: Qt.size(36, 36); asynchronous: true
                            source: Quickshell.iconPath((app.modelData.properties["application.icon-name"] ?? root.appName(app.modelData)).toString().toLowerCase(), true) }
                    Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: root.appName(app.modelData)
                           color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12 }
                    Text { textFormat: Text.PlainText; text: app.modelData.audio ? root.pct(app.modelData.audio.volume) : "--"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
                    Icon { name: app.modelData.audio && app.modelData.audio.muted ? "volume_off" : "volume_up"; size: 18; color: Theme.on_surface_variant
                           MouseArea { anchors.fill: parent; onClicked: if (app.modelData.audio) app.modelData.audio.muted = !app.modelData.audio.muted } }
                }
                MSlider { Layout.fillWidth: true; fill: Theme.accent
                          value: app.modelData.audio ? Math.min(1, app.modelData.audio.volume) : 0
                          onMoved: v => { if (app.modelData.audio) app.modelData.audio.volume = v } }
            }
        }
    }
}
