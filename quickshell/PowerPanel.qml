import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Battery, brightness, volume, power profile and session actions.
Panel {
    id: root
    name: "power"
    panelWidth: 380

    readonly property var battery: UPower.displayDevice
    readonly property real pct: battery ? (battery.percentage > 1 ? battery.percentage : battery.percentage * 100) : 0
    readonly property bool charging: battery && battery.state === UPowerDeviceState.Charging

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

    // ---- battery ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Icon { name: root.charging ? "battery_charging_full" : "battery_full"; size: 36; fill: 1
               color: root.charging ? Theme.primary : root.pct <= 15 ? Theme.error : Theme.on_surface }
        ColumnLayout {
            spacing: 0
            Text { textFormat: Text.PlainText; text: Math.round(root.pct) + "%"; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 22; font.bold: true }
            Text { textFormat: Text.PlainText; text: root.charging ? "Charging" : (root.battery && root.battery.state === UPowerDeviceState.FullyCharged ? "Fully charged" : "On battery")
                   color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 11 }
        }
    }

    // ---- sliders ----
    RowLayout {
        Layout.fillWidth: true; spacing: 10
        Icon { name: "light_mode"; size: 20; color: Theme.on_surface_variant }
        MSlider { Layout.fillWidth: true; value: root.brightness; onMoved: v => root.setBrightness(v) }
        Text { textFormat: Text.PlainText; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight; text: Math.round(root.brightness * 100) + "%"
               color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 11 }
    }
    RowLayout {
        Layout.fillWidth: true; spacing: 10
        Icon { name: root.hasAudio && root.sink.audio.muted ? "volume_off" : "volume_up"; size: 20; color: Theme.on_surface_variant
               MouseArea { anchors.fill: parent; onClicked: if (root.hasAudio) root.sink.audio.muted = !root.sink.audio.muted } }
        MSlider { Layout.fillWidth: true; value: root.hasAudio ? root.sink.audio.volume : 0
                  onMoved: v => { if (root.hasAudio) root.sink.audio.volume = v } }
        Text { textFormat: Text.PlainText; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight; text: root.hasAudio ? Math.round(root.sink.audio.volume * 100) + "%" : "--"
               color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 11 }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outline_variant; opacity: 0.6 }

    // ---- power profile ----
    Text { textFormat: Text.PlainText; text: "Power profile"; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Repeater {
            model: [
                { label: "Saver", icon: "energy_savings_leaf", profile: PowerProfile.PowerSaver },
                { label: "Balanced", icon: "balance", profile: PowerProfile.Balanced },
                { label: "Performance", icon: "speed", profile: PowerProfile.Performance }
            ]
            delegate: Rectangle {
                required property var modelData
                readonly property bool active: PowerProfiles.profile === modelData.profile
                Layout.fillWidth: true
                visible: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                implicitHeight: 56; radius: 16
                color: active ? Theme.primary_container : Theme.surface_container_high
                Behavior on color { ColorAnimation { duration: 180 } }
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 2
                    Icon { Layout.alignment: Qt.AlignHCenter; name: modelData.icon; size: 22; fill: active ? 1 : 0
                           color: active ? Theme.on_primary_container : Theme.on_surface_variant }
                    Text { textFormat: Text.PlainText; Layout.alignment: Qt.AlignHCenter; text: modelData.label; font.family: "JetBrains Mono"; font.pixelSize: 10
                           color: active ? Theme.on_primary_container : Theme.on_surface_variant }
                }
                MouseArea { anchors.fill: parent; onClicked: PowerProfiles.profile = modelData.profile }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outline_variant; opacity: 0.6 }

    // ---- session: second click within 3 s confirms ----
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Repeater {
            model: [
                { label: "Log out", icon: "logout", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
                { label: "Suspend", icon: "bedtime", cmd: ["systemctl", "suspend"] },
                { label: "Restart", icon: "restart_alt", cmd: ["systemctl", "reboot"] },
                { label: "Power off", icon: "power_settings_new", cmd: ["systemctl", "poweroff"] }
            ]
            delegate: Rectangle {
                id: btn
                required property var modelData
                property bool armed: false
                Layout.fillWidth: true
                implicitHeight: 56; radius: 16
                color: armed ? Theme.error : Theme.surface_container_high
                Behavior on color { ColorAnimation { duration: 180 } }
                Timer { id: disarm; interval: 3000; onTriggered: btn.armed = false }
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 2
                    Icon { Layout.alignment: Qt.AlignHCenter; name: btn.modelData.icon; size: 22; color: btn.armed ? Theme.surface : Theme.on_surface_variant }
                    Text { textFormat: Text.PlainText; Layout.alignment: Qt.AlignHCenter; text: btn.armed ? "Sure?" : btn.modelData.label
                           font.family: "JetBrains Mono"; font.pixelSize: 10; color: btn.armed ? Theme.surface : Theme.on_surface_variant }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (btn.armed) { Popups.close(); Quickshell.execDetached(btn.modelData.cmd) }
                        else { btn.armed = true; disarm.restart() }
                    }
                }
            }
        }
    }
}
