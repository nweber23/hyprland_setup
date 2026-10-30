import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

// Wi-Fi networks and Bluetooth devices. Known and open networks connect with one click;
// a new secured network opens a password field under the list.
Panel {
    id: root
    name: "network"
    panelWidth: 400

    onShownChanged: {
        if (Net.wifiDevice) Net.wifiDevice.scannerEnabled = shown
        if (!shown) { pending = null; error = "" }
    }

    property var pending: null      // secured network waiting for a password
    property string error: ""
    function join(net) {
        if (net.connected) { net.disconnect(); return }
        if (net.known || net.security === WifiSecurityType.Open) { net.connect(); return }
        error = ""; pending = net; pwd.text = ""; pwd.forceActiveFocus()
    }
    function submit() {
        if (!pending || pwd.text === "") return
        error = ""
        pending.connectWithPsk(pwd.text)
        pwd.text = ""   // do not keep the secret around
    }
    // Success closes the form, a failure is shown under it.
    Connections {
        target: root.pending
        ignoreUnknownSignals: true
        function onConnectedChanged() { if (root.pending && root.pending.connected) root.pending = null }
        function onConnectionFailed(reason) { root.error = "Could not connect (wrong password?)" }
    }

    function bars(s) { s = s > 1 ? s / 100 : s; return s > 0.66 ? "wifi" : s > 0.33 ? "wifi_2_bar" : "wifi_1_bar" }

    // ---- Wi-Fi ----
    RowLayout {
        Layout.fillWidth: true
        Icon { name: "wifi"; fill: 1; color: Theme.primary }
        Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: "Wi-Fi"; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
        Toggle { checked: Networking.wifiEnabled; onToggled: Networking.wifiEnabled = !Networking.wifiEnabled }
    }
    Repeater {
        model: Networking.wifiEnabled ? Net.wifiList.slice(0, 6) : []
        delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 40; radius: 14
            color: modelData.connected ? Theme.primary_container : area.containsMouse ? Theme.surface_container_high : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                Icon { name: root.bars(modelData.signalStrength); size: 20
                       color: modelData.connected ? Theme.on_primary_container : Theme.on_surface_variant }
                Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: modelData.name; elide: Text.ElideRight
                       color: modelData.connected ? Theme.on_primary_container : Theme.on_surface
                       font.family: "JetBrains Mono"; font.pixelSize: 12 }
                Icon { visible: modelData.security !== WifiSecurityType.Open; name: "lock"; size: 16; color: Theme.outline }
                Icon { visible: modelData.connected; name: "check"; size: 18; color: Theme.on_primary_container }
            }
            MouseArea {
                id: area; anchors.fill: parent; hoverEnabled: true
                onClicked: root.join(modelData)
            }
        }
    }
    // ---- password form for a new secured network ----
    Rectangle {
        Layout.fillWidth: true
        visible: root.pending !== null
        implicitHeight: form.implicitHeight + 20; radius: 16
        color: Theme.surface_container_high
        ColumnLayout {
            id: form
            x: 12; y: 10; width: parent.width - 24; spacing: 6
            Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight
                   text: root.pending ? "Password for " + root.pending.name : ""
                   color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 11 }
            RowLayout {
                spacing: 8
                TextInput {
                    id: pwd
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    color: Theme.on_surface; selectionColor: Theme.primary
                    font.family: "JetBrains Mono"; font.pixelSize: 13
                    clip: true
                    onAccepted: root.submit()
                    Keys.onEscapePressed: { root.pending = null; root.error = "" }
                }
                Rectangle {
                    implicitWidth: 78; implicitHeight: 28; radius: 14; color: Theme.primary
                    Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: "Connect"; color: Theme.on_primary; font.family: "JetBrains Mono"; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; onClicked: root.submit() }
                }
            }
            Text { textFormat: Text.PlainText; visible: root.error !== ""; text: root.error
                   color: Theme.error; font.family: "JetBrains Mono"; font.pixelSize: 10 }
        }
    }
    Text { textFormat: Text.PlainText;
        visible: Networking.wifiEnabled && Net.wifiList.length === 0
        text: "Scanning…"; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 11
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outline_variant; opacity: 0.6 }

    // ---- Bluetooth ----
    RowLayout {
        Layout.fillWidth: true
        Icon { name: "bluetooth"; fill: 1; color: Theme.primary }
        Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: "Bluetooth"; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
        Icon { visible: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
               name: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "bluetooth_searching" : "search"; size: 20
               color: Theme.on_surface_variant
               MouseArea { anchors.fill: parent; onClicked: Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering } }
        Toggle {
            visible: Bluetooth.defaultAdapter !== null
            checked: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
            onToggled: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
        }
    }
    Text { textFormat: Text.PlainText; visible: Bluetooth.defaultAdapter === null; text: "No Bluetooth adapter"; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 11 }
    Repeater {
        model: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? Net.btList.slice(0, 6) : []
        delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 40; radius: 14
            color: modelData.connected ? Theme.primary_container : barea.containsMouse ? Theme.surface_container_high : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                Icon { name: modelData.connected ? "bluetooth_connected" : "bluetooth"; size: 20
                       color: modelData.connected ? Theme.on_primary_container : Theme.on_surface_variant }
                Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: modelData.name; elide: Text.ElideRight
                       color: modelData.connected ? Theme.on_primary_container : Theme.on_surface
                       font.family: "JetBrains Mono"; font.pixelSize: 12 }
                Text { textFormat: Text.PlainText; visible: modelData.batteryAvailable
                       text: Math.round(modelData.battery * (modelData.battery > 1 ? 1 : 100)) + "%"
                       color: modelData.connected ? Theme.on_primary_container : Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 11 }
            }
            MouseArea {
                id: barea; anchors.fill: parent; hoverEnabled: true
                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            }
        }
    }
}
