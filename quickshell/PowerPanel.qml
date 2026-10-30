import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Battery gauge, brightness and volume, session buttons and the power profile.
Panel {
    id: root
    name: "power"
    panelWidth: 380

    readonly property var battery: UPower.displayDevice
    readonly property real pct: battery ? (battery.percentage > 1 ? battery.percentage : battery.percentage * 100) : 0
    readonly property bool charging: battery && battery.state === UPowerDeviceState.Charging
    readonly property bool full: battery && battery.state === UPowerDeviceState.FullyCharged

    // brightness via brightnessctl (0..1)
    property real brightness: 1
    Process {
        id: bget
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: { const p = text.trim().split(",")[3]; if (p) root.brightness = parseInt(p) / 100 }
        }
    }
    onShownChanged: if (shown) bget.running = true
    function setBrightness(v) {
        brightness = v
        Quickshell.execDetached(["brightnessctl", "set", Math.max(1, Math.round(v * 100)) + "%"])   // never 0: black screen
    }

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }
    readonly property bool hasAudio: sink !== null && sink.audio !== null

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ---- clock boxes + logout ----
    Reveal { p: root; index: 0; dx: -16; dy: 8
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Rectangle { implicitWidth: 46; implicitHeight: 44; radius: 10; color: Theme.card
            Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: Qt.formatTime(clock.date, "HH"); color: Theme.accent; font.family: Theme.mono; font.pixelSize: 20; font.bold: true } }
        Text { textFormat: Text.PlainText; text: ":"; color: Theme.outline; font.family: Theme.mono; font.pixelSize: 22 }
        Rectangle { implicitWidth: 46; implicitHeight: 44; radius: 10; color: Theme.card
            Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: Qt.formatTime(clock.date, "mm"); color: Theme.accent; font.family: Theme.mono; font.pixelSize: 20; font.bold: true } }
        Item { Layout.fillWidth: true }
        ActionTile { implicitWidth: 40; implicitHeight: 40; icon: "logout"; needsConfirm: true
               onActivated: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]) }
    }
    }

    // ---- battery ring ----
    Reveal { p: root; index: 1; dy: 14; back: true
    Item {
        Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 6
        implicitWidth: 230; implicitHeight: 230
        Gauge { anchors.fill: parent; value: root.pct / 100; thickness: 14
                color: root.pct <= 15 && !root.charging ? Theme.error : Theme.accent }
        ColumnLayout {
            anchors.centerIn: parent; spacing: 0
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 6
                Icon { name: root.charging ? "battery_charging_full" : "battery_full"; size: 22; fill: 1; color: Theme.accent }
                Text { textFormat: Text.PlainText; text: Math.round(root.pct) + "%"; color: Theme.on_surface
                       font.family: Theme.mono; font.pixelSize: 40; font.bold: true }
            }
            Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText
                   text: root.charging ? "CHARGING" : root.full ? "FULLY CHARGED" : "NOT CHARGING"
                   color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
        }
    }
    }

    // ---- sliders ----
    Reveal { p: root; index: 2
    Rectangle {
        Layout.fillWidth: true; implicitHeight: sl.implicitHeight + 28; radius: 12; color: Theme.card
        ColumnLayout {
            id: sl
            x: 14; y: 14; width: parent.width - 28; spacing: 12
            RowLayout {
                spacing: 12
                Icon { name: "light_mode"; size: 20; color: Theme.accent }
                MSlider { Layout.fillWidth: true; value: root.brightness; fill: Theme.accent; onMoved: v => root.setBrightness(v) }
            }
            RowLayout {
                spacing: 12
                Icon { name: root.hasAudio && root.sink.audio.muted ? "volume_off" : "volume_up"; size: 20; color: Theme.accent2
                       MouseArea { anchors.fill: parent; onClicked: if (root.hasAudio) root.sink.audio.muted = !root.sink.audio.muted } }
                MSlider { Layout.fillWidth: true; value: root.hasAudio ? root.sink.audio.volume : 0; fill: Theme.accent2
                          onMoved: v => { if (root.hasAudio) root.sink.audio.volume = v } }
            }
        }
    }
    }

    // ---- session ----
    Reveal { p: root; index: 3; dy: 14; back: true
    RowLayout {
        Layout.fillWidth: true; spacing: 10
        ActionTile { Layout.fillWidth: true; icon: "lock"; onActivated: { Popups.close(); Quickshell.execDetached(["quickshell", "ipc", "call", "shell", "lock"]) } }
        ActionTile { Layout.fillWidth: true; icon: "bedtime"; onActivated: Quickshell.execDetached(["systemctl", "suspend"]) }
        ActionTile { Layout.fillWidth: true; icon: "restart_alt"; needsConfirm: true; onActivated: Quickshell.execDetached(["systemctl", "reboot"]) }
        ActionTile { Layout.fillWidth: true; icon: "power_settings_new"; needsConfirm: true; onActivated: Quickshell.execDetached(["systemctl", "poweroff"]) }
    }
    }

    // ---- power profile ----
    Reveal { p: root; index: 4; dy: 14; back: true
    Rectangle {
        Layout.fillWidth: true; implicitHeight: 52; radius: 12; color: Theme.card
        RowLayout {
            anchors { fill: parent; margins: 5 }
            spacing: 4
            Repeater {
                model: [
                    { label: "Perform", icon: "speed", profile: PowerProfile.Performance },
                    { label: "Balance", icon: "balance", profile: PowerProfile.Balanced },
                    { label: "Saver", icon: "energy_savings_leaf", profile: PowerProfile.PowerSaver }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: PowerProfiles.profile === modelData.profile
                    readonly property bool avail: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 9
                    opacity: avail ? 1 : 0.35
                    color: active ? Theme.accent2 : "transparent"
                    Behavior on color { ColorAnimation { duration: 180 } }
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        Icon { name: modelData.icon; size: 18; color: active ? Theme.panelBg : Theme.on_surface_variant }
                        Text { textFormat: Text.PlainText; text: modelData.label; font.family: Theme.mono; font.pixelSize: 12
                               color: active ? Theme.panelBg : Theme.on_surface_variant }
                    }
                    MouseArea { anchors.fill: parent; enabled: avail; onClicked: PowerProfiles.profile = modelData.profile }
                }
            }
        }
    }
    }
}
