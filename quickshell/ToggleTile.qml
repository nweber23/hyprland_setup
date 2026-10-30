import QtQuick
import QtQuick.Layouts

// Quick toggle with an icon and a caption; lit in the accent colour while on, dimmed when unavailable.
Rectangle {
    id: tile
    property string icon: ""
    property string label: ""
    property bool on: false
    property bool available: true
    signal toggled()
    implicitHeight: 58; radius: 12
    color: on ? Theme.accent : (area.containsMouse && available ? Theme.cardHigh : Theme.card)
    opacity: available ? 1 : 0.4
    scale: area.pressed ? 0.93 : (area.containsMouse && available ? 1.06 : 1)
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 } }
    ColumnLayout {
        anchors.centerIn: parent; spacing: 3
        Icon { Layout.alignment: Qt.AlignHCenter; name: tile.icon; size: 20; color: tile.on ? Theme.panelBg : Theme.on_surface
               rotation: area.containsMouse ? -10 : 0; Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 3 } } }
        Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: tile.label
               color: tile.on ? Theme.panelBg : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 9; font.bold: true }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; enabled: tile.available; onClicked: tile.toggled() }
}
