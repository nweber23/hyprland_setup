import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Now playing: round cover, seek bar, transport controls and the 10-band equalizer.
Panel {
    id: root
    name: "music"
    panelWidth: 360

    readonly property var player: {
        const ps = Mpris.players.values
        for (let i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i]
        return ps.length > 0 ? ps[0] : null
    }
    readonly property real len: player && player.lengthSupported ? player.length : 0
    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }

    // position is not pushed by MPRIS: poll once a second while the panel is open
    Timer {
        running: root.shown && root.player !== null && root.player.isPlaying
        interval: 1000; repeat: true
        onTriggered: root.player.positionChanged()
    }

    // ---- cover + track ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 14
        ClippingRectangle {
            id: cover
            Layout.preferredWidth: 96; Layout.preferredHeight: 96
            radius: width / 2
            color: Theme.surface_container_high
            Icon { anchors.centerIn: parent; name: "music_note"; size: 40; color: Theme.on_surface_variant }
            Image {
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
            // Spins while playing; stopping keeps the current angle.
            RotationAnimator on rotation {
                from: 0; to: 360; duration: 14000; loops: Animation.Infinite
                running: root.shown && root.player !== null && root.player.isPlaying
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight
                   text: root.player ? root.player.trackTitle : "Nothing playing"
                   color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
            Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight
                   text: root.player ? root.player.trackArtist : ""
                   color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 12 }
            Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight
                   text: root.player ? root.player.identity : ""
                   color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 10 }
        }
    }

    // ---- seek ----
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        visible: root.player !== null
        Text { textFormat: Text.PlainText; text: root.fmt(root.player ? root.player.position : 0)
               color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 10 }
        MSlider {
            Layout.fillWidth: true
            enabled: root.player !== null && root.player.canSeek && root.len > 0
            value: root.len > 0 ? Math.min(1, root.player.position / root.len) : 0
            onMoved: v => { root.player.position = v * root.len }
        }
        Text { textFormat: Text.PlainText; text: root.fmt(root.len)
               color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 10 }
    }

    // ---- transport ----
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 22
        visible: root.player !== null
        Icon { name: "skip_previous"; size: 30; MouseArea { anchors.fill: parent; onClicked: root.player.previous() } }
        Rectangle {   // the filled *_circle glyphs render with artifacts, so draw the disc ourselves
            Layout.preferredWidth: 46; Layout.preferredHeight: 46; radius: 23
            color: Theme.primary
            scale: playArea.pressed ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
            Icon { anchors.centerIn: parent; name: root.player && root.player.isPlaying ? "pause" : "play_arrow"; size: 28; fill: 1; color: Theme.on_primary }
            MouseArea { id: playArea; anchors.fill: parent; onClicked: root.player.togglePlaying() }
        }
        Icon { name: "skip_next"; size: 30; MouseArea { anchors.fill: parent; onClicked: root.player.next() } }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outline_variant; opacity: 0.6 }

    // ---- equalizer ----
    RowLayout {
        Layout.fillWidth: true
        Text { textFormat: Text.PlainText; text: "Equalizer"; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
        Item { Layout.fillWidth: true }
        Text { textFormat: Text.PlainText; text: Eq.node ? (Eq.enabled ? "on" : "off") : "starting…"
               color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 11 }
        Toggle { enabled: Eq.node !== null; checked: Eq.enabled; onToggled: Eq.setEnabled(!Eq.enabled) }
    }
    RowLayout {
        Layout.fillWidth: true; spacing: 6
        Repeater {
            model: Object.keys(Eq.presets)
            delegate: Rectangle {
                required property string modelData
                readonly property bool active: Eq.preset === modelData
                Layout.fillWidth: true
                implicitHeight: 28; radius: 14
                color: active ? Theme.primary_container : Theme.surface_container_high
                Behavior on color { ColorAnimation { duration: 180 } }
                Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData
                       color: active ? Theme.on_primary_container : Theme.on_surface_variant
                       font.family: "JetBrains Mono"; font.pixelSize: 10 }
                MouseArea { anchors.fill: parent; onClicked: Eq.setPreset(modelData) }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 0
        Repeater {
            model: 10
            delegate: EqBand {
                required property int index
                Layout.fillWidth: true
                label: Eq.freqLabels[index]
                range: Eq.range
                value: Eq.gains[index]
                onMoved: db => Eq.setBand(index, db)
            }
        }
    }
}
