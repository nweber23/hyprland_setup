import QtQuick
import QtQuick.Layouts

// One entry of the notification history. It slides in after the rows above it (also when it arrives while open).
Reveal {
    id: root
    property string app: ""
    property string summary: ""
    property string body: ""
    property string icon: ""
    property real time: 0
    property int row: 0              // position in the list
    property string ago: ""
    signal removeRequested()
    signal muteRequested()
    base: 120; step: 55; dx: 40; dy: 0; duration_: 520
    index: Math.min(8, row)

    Rectangle {
        Layout.fillWidth: true; implicitHeight: col.implicitHeight + 22; radius: 12; color: Theme.card
        scale: area.containsMouse ? 1.015 : 1
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2 } }
        RowLayout {
            id: col
            x: 12; y: 11; width: parent.width - 24; spacing: 10
            Image { Layout.preferredWidth: 32; Layout.preferredHeight: 32; Layout.alignment: Qt.AlignTop; sourceSize: Qt.size(64, 64); asynchronous: true
                    visible: root.icon !== ""; source: root.icon }
            Icon { visible: root.icon === ""; Layout.alignment: Qt.AlignTop; name: "notifications"; size: 28; color: Theme.on_surface_variant }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                RowLayout {
                    Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: root.app; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
                    Text { textFormat: Text.PlainText; text: root.ago; color: Theme.outline; font.family: Theme.mono; font.pixelSize: 10 }
                }
                Text { Layout.fillWidth: true; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; textFormat: Text.PlainText; text: root.summary
                       color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12; font.bold: true }
                Text { Layout.fillWidth: true; visible: text !== ""; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; textFormat: Text.PlainText; text: root.body
                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
            }
            Icon { Layout.alignment: Qt.AlignTop; name: "notifications_off"; size: 16; color: muteArea.containsMouse ? Theme.accent : Theme.on_surface_variant
                   opacity: area.containsMouse ? 1 : 0   // appears on hover: stop pop-ups from this app
                   Behavior on opacity { NumberAnimation { duration: 150 } }
                   Behavior on color { ColorAnimation { duration: 150 } }
                   MouseArea { id: muteArea; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: root.muteRequested() } }
            Icon { Layout.alignment: Qt.AlignTop; name: "close"; size: 16; color: closeArea.containsMouse ? Theme.error : Theme.on_surface_variant
                   opacity: area.containsMouse ? 1 : 0.35; rotation: closeArea.containsMouse ? 90 : 0
                   Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                   Behavior on color { ColorAnimation { duration: 150 } }
                   MouseArea { id: closeArea; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: root.removeRequested() } }
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; z: -1 }
    }
}
