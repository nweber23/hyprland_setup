import QtQuick
import QtQuick.Layouts

// One setting: title and hint on the left, the control (children) on the right.
Rectangle {
    id: root
    property string title: ""
    property string hint: ""
    default property alias control: slot.data
    Layout.fillWidth: true
    implicitHeight: Math.max(60, Math.max(texts.implicitHeight, slot.implicitHeight) + 24)
    radius: 12; color: Theme.card
    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        spacing: 16
        ColumnLayout {
            id: texts
            Layout.fillWidth: true; spacing: 2
            Text { Layout.fillWidth: true; textFormat: Text.PlainText; text: root.title; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
            Text { Layout.fillWidth: true; visible: root.hint !== ""; wrapMode: Text.Wrap; textFormat: Text.PlainText; text: root.hint
                   color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
        }
        RowLayout { id: slot; Layout.alignment: Qt.AlignVCenter; spacing: 8 }
    }
}
