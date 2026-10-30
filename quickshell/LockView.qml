import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// Content of the lock screen: blurred wallpaper, big clock, user and password field, status chips.
// Separate from Lock.qml so it can be rendered in a normal window for testing.
Item {
    id: view
    required property var lock          // the Lock scope: checking, error, wallpaper, attempt(), failed()
    property bool shown: false          // drives the fade-in, switched on right after creation
    Component.onCompleted: Qt.callLater(() => shown = true)
    readonly property string user: Quickshell.env("USER") || "user"
    readonly property var battery: UPower.displayDevice
    readonly property int percent: battery ? Math.round(battery.percentage > 1 ? battery.percentage : battery.percentage * 100) : 0

    Rectangle { anchors.fill: parent; color: Theme.surface }

    // wallpaper, blurred and dimmed; fades in once decoded so there is never a black flash after the plain colour
    Image {
        id: bg
        anchors.fill: parent
        source: view.lock.wallpaper !== "" ? "file://" + view.lock.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(view.width, view.height)
        asynchronous: true
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; brightness: -0.1; saturation: 0.15 }
    }
    // darker towards the edges, brighter behind the clock
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Theme.surface, 0.45) }
            GradientStop { position: 0.45; color: Qt.alpha(Theme.surface, 0.10) }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.surface, 0.55) }
        }
    }

    ColumnLayout {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.14 }
        spacing: 2
        opacity: view.shown ? 1 : 0
        transform: Translate { y: view.shown ? 0 : -24; Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } } }
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText
               text: Qt.formatTime(clock.date, "HH:mm"); color: "white"
               font.family: "JetBrains Mono"; font.pixelSize: 132; font.bold: true }
        Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText
               text: Qt.formatDate(clock.date, "dddd, d MMMM"); color: Qt.alpha("white", 0.8)
               font.family: "JetBrains Mono"; font.pixelSize: 20 }
    }

    ColumnLayout {
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: parent.height * 0.14 }
        spacing: 14
        opacity: view.shown ? 1 : 0
        transform: Translate { y: view.shown ? 0 : 30; Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutQuart } } }
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

        Rectangle {   // avatar: first letter on the accent colour
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 84; implicitHeight: 84; radius: 42
            color: Theme.primary_container
            border.width: 2; border.color: Qt.alpha("white", 0.25)
            Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: view.user.charAt(0).toUpperCase()
                   color: Theme.on_primary_container; font.family: "JetBrains Mono"; font.pixelSize: 38; font.bold: true }
        }
        Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: view.user
               color: "white"; font.family: "JetBrains Mono"; font.pixelSize: 17 }

        Rectangle {
            id: field
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 340; implicitHeight: 52; radius: 26
            color: Qt.alpha(Theme.surface_container, 0.75)
            border.width: 1; border.color: view.lock.error !== "" ? Theme.error : Qt.alpha("white", pw.activeFocus ? 0.45 : 0.2)
            Behavior on border.color { ColorAnimation { duration: 160 } }
            SequentialAnimation on x {   // shake on a wrong password
                id: shake; running: false
                NumberAnimation { to: -12; duration: 50 } NumberAnimation { to: 12; duration: 70 }
                NumberAnimation { to: -8; duration: 60 } NumberAnimation { to: 0; duration: 50 }
            }
            Connections { target: view.lock; function onFailed() { pw.text = ""; shake.restart() } }
            RowLayout {
                anchors { fill: parent; leftMargin: 20; rightMargin: 10 }
                spacing: 12
                Icon { name: view.lock.checking ? "hourglass_top" : "lock"; size: 22; color: Theme.on_surface_variant }
                TextInput {
                    id: pw
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    color: Theme.on_surface; selectionColor: Theme.primary
                    font.family: "JetBrains Mono"; font.pixelSize: 16
                    focus: true
                    enabled: !view.lock.checking
                    onAccepted: view.lock.attempt(pw.text)
                    Component.onCompleted: forceActiveFocus()
                    Text { visible: pw.text === ""; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText
                           text: "Password"; color: Theme.outline; font: pw.font }
                }
                Rectangle {   // submit button
                    implicitWidth: 36; implicitHeight: 36; radius: 18
                    color: pw.text !== "" ? Theme.primary : Qt.alpha(Theme.primary, 0.25)
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Icon { anchors.centerIn: parent; name: "arrow_forward"; size: 20; color: Theme.on_primary }
                    MouseArea { anchors.fill: parent; onClicked: view.lock.attempt(pw.text) }
                }
            }
        }
        Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText
               text: view.lock.error; opacity: view.lock.error !== "" ? 1 : 0; color: Theme.error
               font.family: "JetBrains Mono"; font.pixelSize: 13; Behavior on opacity { NumberAnimation { duration: 160 } } }
    }

    // status chips along the bottom
    RowLayout {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 36 }
        spacing: 10
        opacity: view.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
        Repeater {
            model: [
                { icon: "keyboard", text: Keyboard.layout },
                { icon: view.battery && (view.battery.state === UPowerDeviceState.Charging) ? "battery_charging_full" : "battery_full", text: view.percent + "%" },
            ]
            delegate: Rectangle {
                required property var modelData
                implicitWidth: chip.implicitWidth + 24; implicitHeight: 34; radius: 17
                color: Qt.alpha(Theme.surface_container, 0.7)
                RowLayout { id: chip; anchors.centerIn: parent; spacing: 6
                    Icon { name: modelData.icon; size: 18; color: Theme.on_surface_variant }
                    Text { textFormat: Text.PlainText; text: modelData.text; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 12 } }
            }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
