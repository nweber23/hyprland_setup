import QtQuick
import QtQuick.Layouts

// One line of the shortcut overview: the keys as little caps, then what they do.
RowLayout {
    id: row
    property string keys: ""
    property string what: ""
    Layout.fillWidth: true
    spacing: 8
    Row {
        Layout.preferredWidth: 178
        spacing: 3
        Repeater {
            model: row.keys.split("+").filter(k => k !== "")
            delegate: Rectangle {
                required property string modelData
                width: cap.implicitWidth + 12; height: 22; radius: 6
                color: Theme.cardHigh
                border.width: 1; border.color: Qt.alpha(Theme.outline, 0.5)
                Text { id: cap; anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData
                       color: Theme.accent; font.family: Theme.mono; font.pixelSize: 10; font.bold: true }
            }
        }
        Text { visible: row.keys.endsWith("+"); textFormat: Text.PlainText; text: "+"; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 10 }   // the plus key itself
    }
    Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: row.what
           color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11 }
}
