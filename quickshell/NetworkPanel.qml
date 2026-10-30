import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

// Wi-Fi and Bluetooth in one panel, as in the original: a radial view (this computer <-> what it is connected
// to, with info chips), a tab switch at the bottom, and "Scan" which flips to the lists to join something new.
Panel {
    id: root
    name: "network"
    panelWidth: 760
    pad: 24

    readonly property bool isBt: Popups.tab === "bluetooth"
    property bool listMode: false
    onShownChanged: if (!shown) listMode = false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var wnet: Net.wifiNetwork
    readonly property var bdev: Net.btDevice
    function pct(v) { return Math.round(v > 1 ? v : v * 100) }
    function deviceType(d) {
        const i = d ? (d.icon || "") : ""
        return i.includes("headphone") || i.includes("headset") ? "Headphones" : i.includes("mouse") ? "Mouse" : i.includes("keyboard") ? "Keyboard"
             : i.includes("phone") ? "Phone" : i.includes("speaker") ? "Speaker" : i.includes("computer") ? "Computer" : "Device"
    }
    function deviceIcon(d) {
        const t = deviceType(d)
        return t === "Headphones" ? "headphones" : t === "Mouse" ? "mouse" : t === "Keyboard" ? "keyboard" : t === "Phone" ? "smartphone" : t === "Speaker" ? "speaker" : "bluetooth_connected"
    }

    readonly property var wifiLeft: ({
        tone: Theme.accent, icon: "computer", title: "This computer",
        status: Networking.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off", online: Networking.wifiEnabled,
        chips: [
            { icon: "settings_ethernet", value: Net.wifiDevice ? Net.wifiDevice.name : "—", label: "Interface" },
            { icon: "travel_explore", value: String(Net.wifiList.length), label: "Networks in range" },
            { icon: "tag", value: Net.wifiDevice ? Net.wifiDevice.address : "—", label: "MAC Address" }
        ] })
    readonly property var wifiRight: ({
        tone: Theme.accent2, icon: "wifi", title: wnet ? wnet.name : "Not connected", status: wnet ? "Connected" : "—", online: wnet !== null,
        chips: [
            { icon: "network_wifi", value: wnet ? pct(wnet.signalStrength) + "%" : "—", label: "Signal" },
            { icon: "lock", value: wnet ? (wnet.security === WifiSecurityType.Open ? "Open" : "Secured") : "—", label: "Security" },
            { icon: "bookmark", value: wnet ? (wnet.known ? "Saved" : "New") : "—", label: "Profile" }
        ] })
    readonly property var btLeft: ({
        tone: Theme.accent, icon: "bluetooth", title: "This computer",
        status: root.adapter && root.adapter.enabled ? "Bluetooth on" : "Bluetooth off", online: root.adapter !== null && root.adapter.enabled,
        chips: [
            { icon: "memory", value: root.adapter ? root.adapter.adapterId : "—", label: "Adapter" },
            { icon: "radar", value: root.adapter && root.adapter.discovering ? "Scanning" : "Idle", label: "Discovery" },
            { icon: "devices", value: String(Net.btList.length), label: "Paired devices" }
        ] })
    readonly property var btRight: ({
        tone: Theme.accent2, icon: deviceIcon(bdev), title: bdev ? bdev.name : "No device", status: bdev ? "Connected" : "—", online: bdev !== null,
        chips: [
            { icon: "battery_full", value: bdev && bdev.batteryAvailable ? pct(bdev.battery) + "%" : "—", label: "Battery" },
            { icon: "category", value: bdev ? deviceType(bdev) : "—", label: "Type" },
            { icon: "tag", value: bdev ? bdev.address : "—", label: "MAC Address" }
        ] })

    // ---- stage: radial view or list ----
    Reveal {
        p: root; index: 0; dy: 14
        Item {
            Layout.fillWidth: true; implicitHeight: 480

            // radial: the two tabs sit on top of each other and slide/fade past one another
            Item {
                anchors.fill: parent
                opacity: root.listMode ? 0 : 1
                visible: opacity > 0.01
                scale: root.listMode ? 0.96 : 1
                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

                NetView {
                    anchors.fill: parent
                    leftNode: root.wifiLeft; rightNode: root.wifiRight
                    shown: root.shown && !root.listMode && !root.isBt
                    opacity: root.isBt ? 0 : 1
                    x: root.isBt ? -60 : 0
                    Behavior on opacity { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                }
                NetView {
                    anchors.fill: parent
                    leftNode: root.btLeft; rightNode: root.btRight
                    shown: root.shown && !root.listMode && root.isBt
                    opacity: root.isBt ? 1 : 0
                    x: root.isBt ? 0 : 60
                    Behavior on opacity { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                }

                // centre button between the nodes
                Rectangle {
                    x: (parent.width - width) / 2; y: parent.height * 0.49 - height / 2
                    width: 176; height: 56; radius: 14
                    color: scanArea.containsMouse ? Theme.cardHigh : Theme.card
                    border.width: 1; border.color: Theme.cardHigh
                    scale: scanArea.pressed ? 0.95 : 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                    RowLayout {
                        anchors.centerIn: parent; spacing: 10
                        Icon { name: "search"; size: 22; color: Theme.accent }
                        ColumnLayout { spacing: 0
                            Text { textFormat: Text.PlainText; text: root.isBt ? "Scan Devices" : "Scan Networks"; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 12; font.bold: true }
                            Text { textFormat: Text.PlainText; text: "Switch View"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 9 } }
                    }
                    MouseArea { id: scanArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.listMode = true }
                }
            }

            // list: join or pair something new
            Item {
                anchors.fill: parent
                opacity: root.listMode ? 1 : 0
                visible: opacity > 0.01
                y: root.listMode ? 0 : 24
                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                Rectangle {
                    id: backBtn
                    width: backRow.implicitWidth + 24; height: 32; radius: 10; color: backArea.containsMouse ? Theme.cardHigh : Theme.card
                    Behavior on color { ColorAnimation { duration: 150 } }
                    RowLayout { id: backRow; anchors.centerIn: parent; spacing: 6
                        Icon { name: "arrow_back"; size: 16; color: Theme.accent }
                        Text { textFormat: Text.PlainText; text: "Overview"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11; font.bold: true } }
                    MouseArea { id: backArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.listMode = false }
                }
                Flickable {
                    anchors { left: parent.left; right: parent.right; top: backBtn.bottom; topMargin: 12; bottom: parent.bottom }
                    contentHeight: lists.implicitHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
                    Item {
                        id: lists
                        width: parent.width; implicitHeight: root.isBt ? bt.implicitHeight : wifi.implicitHeight
                        WifiList { id: wifi; width: parent.width; active: root.listMode && root.shown && !root.isBt; visible: !root.isBt }
                        BtList { id: bt; width: parent.width; active: root.listMode && root.shown && root.isBt; visible: root.isBt }
                    }
                }
            }
        }
    }

    // ---- bottom: tab switch + radio power ----
    Reveal {
        p: root; index: 1; dy: 14; back: true
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            Rectangle {
                implicitWidth: 320; implicitHeight: 46; radius: 15; color: Theme.card
                Rectangle {   // sliding highlight
                    y: 4; height: 38; width: 154; radius: 11; color: Theme.accent
                    x: 4 + (root.isBt ? 158 : 0)
                    Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                }
                Row {
                    anchors.fill: parent; anchors.margins: 4; spacing: 4
                    Repeater {
                        model: [{ t: "wifi", label: "Wi-Fi", icon: "wifi" }, { t: "bluetooth", label: "Bluetooth", icon: "bluetooth" }]
                        delegate: Item {
                            required property var modelData
                            readonly property bool on: (modelData.t === "bluetooth") === root.isBt
                            width: 154; height: 38
                            RowLayout {
                                anchors.centerIn: parent; spacing: 8
                                Icon { name: modelData.icon; size: 18; color: on ? Theme.panelBg : Theme.on_surface_variant
                                       Behavior on color { ColorAnimation { duration: 250 } } }
                                Text { textFormat: Text.PlainText; text: modelData.label; font.family: Theme.mono; font.pixelSize: 13; font.bold: true
                                       color: on ? Theme.panelBg : Theme.on_surface_variant
                                       Behavior on color { ColorAnimation { duration: 250 } } }
                            }
                            MouseArea { anchors.fill: parent; onClicked: Popups.tab = modelData.t }
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                // radio on/off for the shown tab
                Rectangle {
                    id: power
                    readonly property bool on: root.isBt ? (root.adapter !== null && root.adapter.enabled) : Networking.wifiEnabled
                    anchors.right: parent.right
                    width: 46; height: 46; radius: 23
                    color: on ? Theme.accent : Theme.card
                    scale: pArea.pressed ? 0.9 : (pArea.containsMouse ? 1.08 : 1)
                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                    Icon { anchors.centerIn: parent; name: "power_settings_new"; size: 22; color: power.on ? Theme.panelBg : Theme.on_surface_variant
                           rotation: power.on ? 0 : -90
                           Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack } } }
                    MouseArea {
                        id: pArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: { if (root.isBt) { if (root.adapter) root.adapter.enabled = !root.adapter.enabled } else Networking.wifiEnabled = !Networking.wifiEnabled }
                    }
                }
            }
        }
    }
}
