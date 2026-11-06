import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// Widgets on the bare desktop: clock with weather, battery and the playing track. They sit below all windows
// (layer Bottom) and only take clicks where a widget is, so the desktop behind stays usable.
PanelWindow {
    id: win
    visible: Settings.widgets && !Popups.locked
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-widgets"
    color: "transparent"
    mask: Region { Region { item: clockBox } Region { item: batBox } Region { item: musicBox } }

    readonly property var player: {
        const ps = Mpris.players.values
        for (let i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i]
        return ps.length > 0 ? ps[0] : null
    }
    readonly property var battery: UPower.displayDevice
    readonly property int percent: Math.round(Battery.pct)
    readonly property bool charging: battery && battery.state === UPowerDeviceState.Charging

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ---- clock + weather ----
    ColumnLayout {
        id: clockBox
        x: 56; y: 96
        spacing: 0
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#99000000"; shadowBlur: 0.8; shadowVerticalOffset: 3 }
        Text { textFormat: Text.PlainText; text: Qt.formatTime(clock.date, "HH:mm"); color: "white"
               font.family: Theme.mono; font.pixelSize: 112; font.bold: true }
        Text { textFormat: Text.PlainText; text: Qt.formatDate(clock.date, "dddd, d MMMM"); color: Qt.alpha("white", 0.85)
               font.family: Theme.mono; font.pixelSize: 20 }
        RowLayout {
            visible: Weather.temp !== ""; Layout.topMargin: 6; spacing: 8
            Icon { name: Weather.icon; size: 22; color: "white" }
            Text { textFormat: Text.PlainText; text: Weather.temp + (Weather.desc !== "" ? "  ·  " + Weather.desc : ""); color: Qt.alpha("white", 0.85)
                   font.family: Theme.mono; font.pixelSize: 15 }
        }
    }

    // ---- battery ----
    Rectangle {
        id: batBox
        x: 56; y: win.height - height - 56
        width: 210; height: 76; radius: 18
        color: Qt.alpha(Theme.surface_container, 0.75)
        border.width: 1; border.color: Qt.alpha("white", 0.1)
        RowLayout {
            anchors { fill: parent; margins: 16 }
            spacing: 12
            Icon { name: win.charging ? "battery_charging_full" : "battery_full"; size: 30; color: win.percent <= 20 && !win.charging ? Theme.error : Theme.accent }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                RowLayout {
                    Text { textFormat: Text.PlainText; text: win.percent + "%"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 20; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Text { textFormat: Text.PlainText; text: win.charging ? "charging" : "battery"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: Theme.card
                    Rectangle { width: parent.width * Math.min(1, win.percent / 100); height: parent.height; radius: 3
                                color: win.percent <= 20 && !win.charging ? Theme.error : Theme.accent
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } } }
                }
            }
        }
    }

    // the bars rise out of the top of the music card
    Row {
        id: vizBox
        visible: win.player !== null
        x: musicBox.x + 8; y: musicBox.y - height - 6
        width: musicBox.width - 16; height: 58
        spacing: 3
        opacity: Spectrum.levels.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
        Repeater {
            model: 24
            delegate: Item {   // a fixed-size cell: items inside a Row cannot be anchored
                required property int index
                readonly property real v: Spectrum.levels.length > index ? Spectrum.levels[index] / 100 : 0
                width: (vizBox.width - 23 * 3) / 24; height: vizBox.height
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: Math.max(3, parent.height * parent.v)
                    radius: width / 2
                    color: Qt.alpha(Theme.accent, 0.45 + 0.55 * parent.v)
                    Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                }
            }
        }
    }

    // ---- music ----
    Rectangle {
        id: musicBox
        visible: win.player !== null
        x: batBox.x + batBox.width + 16; y: batBox.y
        width: 360; height: 76; radius: 18
        color: Qt.alpha(Theme.surface_container, 0.75)
        border.width: 1; border.color: Qt.alpha("white", 0.1)
        RowLayout {
            anchors { fill: parent; margins: 10 }
            spacing: 12
            Rectangle {
                Layout.preferredWidth: 56; Layout.preferredHeight: 56; radius: 12; color: Theme.card; clip: true
                Image { anchors.fill: parent; source: win.player ? win.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true
                        sourceSize: Qt.size(112, 112) }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                       text: win.player ? win.player.trackTitle : ""; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
                Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                       text: win.player ? win.player.trackArtist : ""; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
            }
            Repeater {
                model: [{ i: "skip_previous", a: 0 }, { i: "play", a: 1 }, { i: "skip_next", a: 2 }]
                delegate: Rectangle {
                    required property var modelData
                    Layout.preferredWidth: 34; Layout.preferredHeight: 34; radius: 17
                    color: bm.containsMouse ? Theme.cardHigh : "transparent"
                    Icon { anchors.centerIn: parent; size: 22; fill: 1; color: Theme.on_surface
                           name: modelData.a === 1 ? (win.player && win.player.isPlaying ? "pause" : "play_arrow") : modelData.i }
                    MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true
                                onClicked: { if (!win.player) return; if (modelData.a === 0) win.player.previous(); else if (modelData.a === 1) win.player.togglePlaying(); else win.player.next() } }
                }
            }
        }
    }
}
