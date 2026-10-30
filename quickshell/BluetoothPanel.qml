import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Bluetooth: paired devices on top, devices found nearby below. Click connects, pairs or disconnects.
Panel {
    id: root
    name: "bluetooth"
    panelWidth: 400

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter !== null && adapter.enabled

    // Scan while the panel is open.
    onShownChanged: if (adapter && adapter.enabled) adapter.discovering = shown

    function deviceIcon(d) {
        const i = d.icon || ""
        return i.includes("headphone") || i.includes("headset") ? "headphones"
             : i.includes("mouse") ? "mouse" : i.includes("keyboard") ? "keyboard"
             : i.includes("phone") ? "smartphone" : i.includes("computer") ? "computer"
             : i.includes("speaker") || i.includes("audio") ? "speaker" : d.connected ? "bluetooth_connected" : "bluetooth"
    }
    readonly property var paired: Bluetooth.devices.values.filter(d => d.paired || d.connected)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    // Nearby: unpaired devices with a real name. Ones named after their own MAC address are radio noise.
    readonly property var nearby: Bluetooth.devices.values.filter(d => !d.paired && !d.connected && d.name !== ""
                                                                      && !/^[0-9A-Fa-f]{2}([-:][0-9A-Fa-f]{2}){5}$/.test(d.name))
        .sort((a, b) => a.name.localeCompare(b.name))

    RowLayout {
        Layout.fillWidth: true
        Icon { name: "bluetooth"; fill: 1; color: Theme.primary }
        Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: "Bluetooth"; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
        Icon {
            visible: root.on
            name: root.adapter && root.adapter.discovering ? "bluetooth_searching" : "search"; size: 20
            color: root.adapter && root.adapter.discovering ? Theme.primary : Theme.on_surface_variant
            MouseArea { anchors.fill: parent; onClicked: root.adapter.discovering = !root.adapter.discovering }
        }
        Toggle {
            visible: root.adapter !== null
            checked: root.on
            onToggled: root.adapter.enabled = !root.adapter.enabled
        }
    }
    Text { textFormat: Text.PlainText; visible: root.adapter === null; text: "No Bluetooth adapter"; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 11 }
    Text { textFormat: Text.PlainText; visible: root.adapter !== null && !root.on; text: "Bluetooth is off"; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 11 }

    component DeviceRow: Rectangle {
        id: row
        required property var dev
        property string hint: ""
        signal activated()
        Layout.fillWidth: true
        implicitHeight: 42; radius: 14
        color: dev.connected ? Theme.primary_container : area.containsMouse ? Theme.surface_container_high : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 10
            Icon { name: root.deviceIcon(row.dev); size: 20; color: row.dev.connected ? Theme.on_primary_container : Theme.on_surface_variant }
            Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight; text: row.dev.name
                   color: row.dev.connected ? Theme.on_primary_container : Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 12 }
            Text { textFormat: Text.PlainText; visible: row.dev.batteryAvailable
                   text: Math.round(row.dev.battery * (row.dev.battery > 1 ? 1 : 100)) + "%"
                   color: row.dev.connected ? Theme.on_primary_container : Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 11 }
            Text { textFormat: Text.PlainText; visible: row.dev.pairing || row.hint !== ""
                   text: row.dev.pairing ? "pairing…" : row.hint
                   color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 10 }
            Icon { visible: row.dev.paired && area.containsMouse; name: "delete"; size: 18; color: Theme.on_surface_variant
                   MouseArea { anchors.fill: parent; onClicked: row.dev.forget() } }
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; z: -1; onClicked: row.activated() }
    }

    Text { textFormat: Text.PlainText; visible: root.on && root.paired.length > 0; text: "My devices"
           color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 10 }
    Repeater {
        model: root.on ? root.paired : []
        delegate: DeviceRow {
            required property var modelData
            dev: modelData
            onActivated: dev.connected ? dev.disconnect() : dev.connect()
        }
    }

    Text { textFormat: Text.PlainText; visible: root.on && root.nearby.length > 0; text: "Nearby"
           color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 10 }
    Repeater {
        model: root.on ? root.nearby.slice(0, 6) : []
        delegate: DeviceRow {
            required property var modelData
            dev: modelData
            hint: "tap to pair"
            onActivated: dev.pair()
        }
    }
    Text { textFormat: Text.PlainText; visible: root.on && root.adapter.discovering && root.nearby.length === 0
           text: "Searching…"; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 11 }
}
