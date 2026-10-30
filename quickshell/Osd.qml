import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// On-screen display for volume, mute and brightness changes: a small pill at the bottom of the screen.
Scope {
    id: root
    property string icon: "volume_up"
    property string label: ""        // text instead of a bar (keyboard layout)
    property real value: 0
    property bool shown: false

    function show(icon, value) {
        root.label = ""; root.icon = icon; root.value = value; root.shown = true; hide.restart()
    }
    function showText(icon, text) {
        root.label = text; root.icon = icon; root.shown = true; hide.restart()
    }
    // keyboard layout switched
    Connections { target: Keyboard; function onLayoutChanged() { if (root.ready) root.showText("keyboard", Keyboard.name !== "" ? Keyboard.name : Keyboard.layout) } }
    Timer { id: hide; interval: 1400; onTriggered: root.shown = false }

    // ---- volume / mute ----
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    property bool ready: false          // skip the values that arrive while the shell starts
    Timer { interval: 1500; running: true; onTriggered: root.ready = true }
    onVolChanged: if (ready) show(muted || vol <= 0 ? "volume_off" : vol < 0.34 ? "volume_mute" : vol < 0.67 ? "volume_down" : "volume_up", vol)
    onMutedChanged: if (ready) show(muted ? "volume_off" : "volume_up", muted ? 0 : vol)

    // ---- brightness: sysfs sends no change events, so read the file twice a second (cheap) ----
    property real bright: -1
    Process {
        id: findBl
        running: true
        command: ["sh", "-c", "ls -d /sys/class/backlight/*/ | head -1"]
        stdout: StdioCollector { onStreamFinished: { const d = text.trim(); if (d) { cur.path = d + "brightness"; max.path = d + "max_brightness" } } }
    }
    FileView { id: max }
    FileView {
        id: cur
        onLoaded: {
            const m = parseInt(max.text()), c = parseInt(text())
            if (!m) return
            const v = c / m
            if (root.bright >= 0 && Math.abs(v - root.bright) > 0.004) root.show("light_mode", v)
            root.bright = v
        }
    }
    Timer { interval: 500; running: cur.path !== ""; repeat: true; onTriggered: cur.reload() }

    PanelWindow {
        screen: Quickshell.screens[0]
        visible: root.shown || pill.opacity > 0.01
        anchors { bottom: true }
        margins.bottom: 70
        implicitWidth: 260; implicitHeight: 56
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}                    // never takes clicks
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-panel"

        Rectangle {
            id: pill
            anchors.fill: parent
            radius: 28
            color: Qt.alpha(Theme.surface_container, 0.96)
            border.width: 1; border.color: Qt.alpha(Theme.outline_variant, 0.6)
            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: 160 } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            RowLayout {
                anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                spacing: 12
                Icon { name: root.icon; size: 26; color: Theme.primary }   // fill 1 garbles some glyphs (light_mode)
                Text { visible: root.label !== ""; Layout.fillWidth: true; textFormat: Text.PlainText; text: root.label
                       color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
                Rectangle {
                    visible: root.label === ""
                    Layout.fillWidth: true; height: 8; radius: 4; color: Theme.surface_container_high
                    Rectangle { width: parent.width * Math.min(1, root.value); height: parent.height; radius: 4; color: Theme.primary
                                Behavior on width { NumberAnimation { duration: 120 } } }
                }
                Text { visible: root.label === ""; textFormat: Text.PlainText; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight
                       text: Math.round(root.value * 100) + "%"; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 12 }
            }
        }
    }
}
