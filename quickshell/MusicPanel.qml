import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Now playing: spinning vinyl cover, seek bar, transport controls and the 10-band equalizer.
Panel {
    id: root
    name: "music"
    panelWidth: 540

    readonly property var player: {
        const ps = Mpris.players.values
        for (let i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i]
        return ps.length > 0 ? ps[0] : null
    }
    readonly property real len: player && player.lengthSupported ? player.length : 0
    function fmt(s) { s = Math.max(0, Math.floor(s)); return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0") }

    // position is not pushed by MPRIS: poll once a second while the panel is open
    Timer {
        running: root.shown && root.player !== null && root.player.isPlaying
        interval: 1000; repeat: true
        onTriggered: root.player.positionChanged()
    }

    // ---- cover + track ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 22
        Reveal {
            p: root; index: 0; dx: -35; dy: 9; back: true; Layout.fillWidth: false
            Item {
            Layout.preferredWidth: 150; Layout.preferredHeight: 150
            Rectangle { anchors.centerIn: parent; width: 164; height: 164; radius: 82; color: Qt.alpha(Theme.accent2, 0.16) }   // soft glow
            ClippingRectangle {
                id: cover
                anchors.fill: parent
                radius: width / 2
                color: Theme.card
                border.width: 3; border.color: Theme.accent2
                Icon { anchors.centerIn: parent; name: "music_note"; size: 44; color: Theme.on_surface_variant }
                Image {
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
                Rectangle { anchors.centerIn: parent; width: parent.width * 0.14; height: width; radius: width / 2; color: Theme.panelBg }   // vinyl hole
                // Spins while playing; stopping keeps the current angle.
                RotationAnimator on rotation {
                    from: 0; to: 360; duration: 14000; loops: Animation.Infinite
                    running: root.shown && root.player !== null && root.player.isPlaying
                }
            }
            }
        }
        Reveal {
            p: root; index: 1; spacing: 6
            Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight
                   text: root.player ? root.player.trackTitle : "Nothing playing"
                   color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 18; font.bold: true }
            Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight
                   text: root.player && root.player.trackArtist ? "BY " + root.player.trackArtist : ""
                   color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
            RowLayout {
                spacing: 8
                visible: root.player !== null
                Rectangle {
                    visible: Net.btDevice !== null
                    implicitHeight: 24; implicitWidth: btRow.implicitWidth + 16; radius: 7; color: Theme.card
                    RowLayout { id: btRow; anchors.centerIn: parent; spacing: 5
                        Icon { name: "bluetooth"; size: 13; color: Theme.accent2 }
                        Text { textFormat: Text.PlainText; text: Net.btDevice ? Net.btDevice.name : ""; color: Theme.on_surface
                               font.family: Theme.mono; font.pixelSize: 10; font.bold: true } }
                }
                Text { textFormat: Text.PlainText; text: root.player ? "VIA " + root.player.identity : ""
                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10; font.italic: true }
            }
            MSlider {
                Layout.fillWidth: true; Layout.topMargin: 4
                knob: true; fill: Theme.accent2
                visible: root.player !== null
                enabled: root.player !== null && root.player.canSeek && root.len > 0
                value: root.len > 0 ? Math.min(1, root.player.position / root.len) : 0
                onMoved: v => { root.player.position = v * root.len }
            }
            RowLayout {
                Layout.fillWidth: true; visible: root.player !== null
                Text { textFormat: Text.PlainText; text: root.fmt(root.player ? root.player.position : 0)
                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Text { textFormat: Text.PlainText; text: root.fmt(root.len)
                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
            }
        }
    }

    // ---- transport ----
    Reveal { p: root; index: 2; dy: 12; back: true
    RowLayout {
        Layout.alignment: Qt.AlignHCenter; Layout.leftMargin: 150
        spacing: 34
        visible: root.player !== null
        Icon { name: "skip_previous"; size: 30; fill: 1; MouseArea { anchors.fill: parent; onClicked: root.player.previous() } }
        Item {   // pause drawn as two bars (the filled circle glyphs render with artifacts)
            implicitWidth: 34; implicitHeight: 38
            Row { anchors.centerIn: parent; spacing: 6; visible: root.player && root.player.isPlaying
                Rectangle { width: 10; height: 32; radius: 2; color: Theme.accent2 }
                Rectangle { width: 10; height: 32; radius: 2; color: Theme.accent2 } }
            Icon { anchors.centerIn: parent; visible: !(root.player && root.player.isPlaying); name: "play_arrow"; size: 44; fill: 1; color: Theme.accent2 }
            MouseArea { anchors.fill: parent; onClicked: root.player.togglePlaying() }
        }
        Icon { name: "skip_next"; size: 30; fill: 1; MouseArea { anchors.fill: parent; onClicked: root.player.next() } }
    }
    }

    Reveal { p: root; index: 3
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardHigh }
    }

    // ---- equalizer ----
    Reveal { p: root; index: 4
    RowLayout {
        Layout.fillWidth: true
        Text { textFormat: Text.PlainText; text: "Equalizer"; color: Theme.accent2; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
        Item { Layout.fillWidth: true }
        Rectangle {   // routes the system audio through the equalizer
            implicitHeight: 26; implicitWidth: onTxt.implicitWidth + 22; radius: 8
            color: Eq.enabled ? Theme.accent2 : Theme.card
            opacity: Eq.node !== null ? 1 : 0.4
            Behavior on color { ColorAnimation { duration: 160 } }
            Text { id: onTxt; anchors.centerIn: parent; textFormat: Text.PlainText; text: Eq.enabled ? "ON" : "OFF"
                   color: Eq.enabled ? Theme.panelBg : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11; font.bold: true }
            MouseArea { anchors.fill: parent; enabled: Eq.node !== null; onClicked: Eq.setEnabled(!Eq.enabled) }
        }
        Rectangle { implicitHeight: 26; implicitWidth: savedTxt.implicitWidth + 22; radius: 8; color: Theme.card
            Text { id: savedTxt; anchors.centerIn: parent; textFormat: Text.PlainText; text: "Saved"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 } }
        Text { textFormat: Text.PlainText; text: Eq.preset; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13 }
    }
    }

    Reveal { p: root; index: 5; dy: 16; easing_: Easing.OutExpo; duration_: 860
    RowLayout {
        Layout.fillWidth: true
        spacing: 0
        Repeater {
            model: 10
            delegate: EqBand {
                required property int index
                Layout.fillWidth: true
                implicitHeight: 160
                label: Eq.freqLabels[index]
                range: Eq.range
                value: Eq.gains[index]
                onMoved: db => Eq.setBand(index, db)
            }
        }
    }
    }

    Reveal { p: root; index: 6; dy: 12; back: true
    GridLayout {
        Layout.fillWidth: true
        columns: 4; columnSpacing: 10; rowSpacing: 10
        Repeater {
            model: Eq.presetOrder
            delegate: Rectangle {
                required property string modelData
                readonly property bool active: Eq.preset === modelData
                Layout.fillWidth: true
                implicitHeight: 34; radius: 9
                color: active ? Theme.accent2 : Theme.card
                Behavior on color { ColorAnimation { duration: 160 } }
                Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData
                       color: active ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: Eq.setPreset(modelData) }
            }
        }
    }
    }
}
