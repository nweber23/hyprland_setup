import QtQuick
import QtQuick.Layouts

// Small stat box: caption on top, value below (optional third line).
Rectangle {
    id: root
    property string caption: ""
    property string value: ""
    property string sub: ""
    property color valueColor: Theme.on_surface
    property int valueSize: 18
    implicitHeight: 64; radius: 12; color: Theme.card
    ColumnLayout {
        anchors.centerIn: parent; spacing: 1
        Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: root.caption; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
        Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: root.value; color: root.valueColor; font.family: Theme.mono; font.pixelSize: root.valueSize; font.bold: true }
        Text { Layout.alignment: Qt.AlignHCenter; visible: root.sub !== ""; textFormat: Text.PlainText; text: root.sub; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 9 }
    }
}
