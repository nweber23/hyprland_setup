import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Floating top bar made of separate pills.
PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 12; right: 12 }
    implicitHeight: 34
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"

    readonly property font textFont: Qt.font({ family: "JetBrains Mono", pixelSize: 13 })

    // ---- state ----------------------------------------------------------------
    readonly property var player: {
        const ps = Mpris.players.values
        for (let i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i]
        return ps.length > 0 ? ps[0] : null
    }

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [bar.sink] }
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    readonly property var battery: UPower.displayDevice
    // UPower reports 0..100 on D-Bus; guard in case a build exposes 0..1.
    readonly property real batteryPct: battery ? (battery.percentage > 1 ? battery.percentage : battery.percentage * 100) : 0
    readonly property bool charging: battery && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged)

    property string keymap: "--"
    Process {
        id: kbQuery
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards
                    const main = kbs.find(k => k.main) ?? kbs[0]
                    const names = { "English": "EN", "German": "DE", "French": "FR", "Spanish": "ES" }
                    const lang = main.active_keymap.split(" ")[0]
                    bar.keymap = names[lang] ?? lang.slice(0, 2).toUpperCase()
                } catch (e) {}
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: kbQuery.running = true }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function volumeIcon() {
        if (muted || volume <= 0) return "volume_off"
        return volume < 0.34 ? "volume_mute" : volume < 0.67 ? "volume_down" : "volume_up"
    }
    function batteryIcon() {
        if (charging) return "battery_charging_full"
        const p = batteryPct
        return p > 90 ? "battery_full" : p > 70 ? "battery_5_bar" : p > 50 ? "battery_4_bar"
             : p > 35 ? "battery_3_bar" : p > 20 ? "battery_2_bar" : p > 8 ? "battery_1_bar" : "battery_alert"
    }
    function openPanel(name, item) {
        const p = item.mapToItem(null, item.width / 2, 0)
        Popups.toggle(name, bar.screen.name, p.x + bar.margins.left)
    }
    function focusWorkspace(id) { Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + id + " })"]) }

    // ---- left: workspaces + now playing ---------------------------------------------
    RowLayout {
        anchors.left: parent.left
        height: parent.height
        spacing: 8

        Chip {
            Layout.fillHeight: true
            Row {
                spacing: 6
                Repeater {
                    model: 5
                    delegate: Rectangle {
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property bool active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                        readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)
                        anchors.verticalCenter: parent.verticalCenter
                        height: 10
                        width: active ? 28 : 10
                        radius: 5
                        color: active ? Theme.primary : occupied ? Theme.on_surface_variant : Theme.outline_variant
                        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: bar.focusWorkspace(parent.wsId) }
                    }
                }
            }
        }

        Chip {
            id: mediaChip
            visible: bar.player !== null
            Layout.fillHeight: true
            onClicked: bar.openPanel("music", mediaChip)
            Icon { name: "skip_previous"; size: 20; MouseArea { anchors.fill: parent; onClicked: bar.player.previous() } }
            Icon { name: bar.player && bar.player.isPlaying ? "pause" : "play_arrow"; size: 22; fill: 1; color: Theme.primary
                   MouseArea { anchors.fill: parent; onClicked: bar.player.togglePlaying() } }
            Icon { name: "skip_next"; size: 20; MouseArea { anchors.fill: parent; onClicked: bar.player.next() } }
            Text { textFormat: Text.PlainText;
                Layout.maximumWidth: 240
                text: bar.player ? (bar.player.trackArtist ? bar.player.trackArtist + " – " : "") + bar.player.trackTitle : ""
                color: Theme.on_surface_variant
                font: bar.textFont
                elide: Text.ElideRight
            }
        }
    }

    // ---- centre: clock + weather --------------------------------------------------
    Chip {
        id: clockChip
        anchors.centerIn: parent
        height: parent.height
        highlighted: Popups.current === "calendar" && Popups.screenName === bar.screen.name
        onClicked: bar.openPanel("calendar", clockChip)
        Text { textFormat: Text.PlainText; text: Qt.formatDateTime(clock.date, "ddd d MMM"); color: clockChip.highlighted ? Theme.on_primary_container : Theme.on_surface_variant; font: bar.textFont }
        Text { textFormat: Text.PlainText; text: Qt.formatDateTime(clock.date, "HH:mm"); color: clockChip.highlighted ? Theme.on_primary_container : Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
        Icon { visible: Weather.temp !== ""; name: Weather.icon; size: 18; fill: 1; color: Theme.primary }
        Text { textFormat: Text.PlainText; visible: Weather.temp !== ""; text: Weather.temp; color: Theme.primary; font: bar.textFont }
    }

    // ---- right: tray + status chips ------------------------------------------------
    RowLayout {
        anchors.right: parent.right
        height: parent.height
        spacing: 8

        Chip {
            visible: SystemTray.items.values.length > 0
            Layout.fillHeight: true
            Repeater {
                model: SystemTray.items
                delegate: IconImage {
                    required property var modelData
                    implicitSize: 18
                    source: modelData.icon
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: m => m.button === Qt.LeftButton ? modelData.activate() : modelData.secondaryActivate()
                    }
                }
            }
        }

        Chip {
            Layout.fillHeight: true
            Icon { name: "keyboard"; size: 18 }
            Text { textFormat: Text.PlainText; text: bar.keymap; color: Theme.on_surface; font: bar.textFont }
        }

        Chip {
            id: wifiChip
            Layout.fillHeight: true
            highlighted: Popups.current === "network" && Popups.screenName === bar.screen.name
            onClicked: bar.openPanel("network", wifiChip)
            Icon { name: Net.wifiNetwork ? "wifi" : "wifi_off"; size: 18; fill: 1; color: Net.wifiNetwork ? Theme.primary : Theme.outline }
            Text { textFormat: Text.PlainText; visible: Net.wifiNetwork !== null; text: Net.wifiNetwork ? Net.wifiNetwork.name : ""; color: Theme.on_surface; font: bar.textFont
                   Layout.maximumWidth: 120; elide: Text.ElideRight }
        }

        Chip {
            id: btChip
            Layout.fillHeight: true
            highlighted: Popups.current === "network" && Popups.screenName === bar.screen.name
            onClicked: bar.openPanel("network", btChip)
            Icon { name: Net.btDevice ? "bluetooth_connected" : "bluetooth"; size: 18; fill: 1; color: Net.btDevice ? Theme.primary : Theme.outline }
            Text { textFormat: Text.PlainText; visible: Net.btDevice !== null; color: Theme.on_surface; font: bar.textFont; Layout.maximumWidth: 120; elide: Text.ElideRight
                   text: Net.btDevice ? Net.btDevice.name + (Net.btDevice.batteryAvailable ? " " + Math.round(Net.btDevice.battery * (Net.btDevice.battery > 1 ? 1 : 100)) + "%" : "") : "" }
        }

        Chip {
            id: volChip
            Layout.fillHeight: true
            Icon { name: bar.volumeIcon(); size: 18; fill: 1; color: bar.muted ? Theme.outline : Theme.on_surface }
            Text { textFormat: Text.PlainText; text: Math.round(bar.volume * 100) + "%"; color: Theme.on_surface; font: bar.textFont }
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) { if (bar.sink && bar.sink.audio) bar.sink.audio.muted = !bar.sink.audio.muted }
                else bar.openPanel("power", volChip)
            }
            onScrolled: wheel => {
                if (!bar.sink || !bar.sink.audio) return
                const v = bar.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)
                bar.sink.audio.volume = Math.max(0, Math.min(1, v))
            }
        }

        Chip {
            id: batChip
            visible: bar.battery !== null && bar.battery.isLaptopBattery
            Layout.fillHeight: true
            highlighted: Popups.current === "power" && Popups.screenName === bar.screen.name
            onClicked: bar.openPanel("power", batChip)
            Icon { name: bar.batteryIcon(); size: 18; fill: 1
                   color: bar.charging ? Theme.primary : bar.batteryPct <= 15 ? Theme.error : Theme.on_surface }
            Text { textFormat: Text.PlainText; text: Math.round(bar.batteryPct) + "%"; color: Theme.on_surface; font: bar.textFont }
        }
    }
}
