import QtQuick
import QtQuick.Layouts

// Big button with an icon and a caption.
Rectangle {
    id: t
    property string icon: ""
    property string label: ""
    property color tone: Theme.accent
    property bool danger: false
    signal activated()
    Layout.fillWidth: true; implicitHeight: 76; radius: 12
    color: danger ? Theme.error : (ma.containsMouse ? Theme.cardHigh : Theme.card)
    scale: ma.pressed ? 0.95 : 1
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    ColumnLayout {
        anchors.centerIn: parent; spacing: 5
        Icon { Layout.alignment: Qt.AlignHCenter; name: t.icon; size: 26; color: t.danger ? Theme.panelBg : t.tone }
        Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: t.label
               color: t.danger ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11; font.bold: true }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: t.activated() }
}
