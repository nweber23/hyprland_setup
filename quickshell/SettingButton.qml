import QtQuick

// Small text button for a setting row.
Rectangle {
    id: root
    property string label: ""
    property bool accent: false
    signal clicked()
    implicitHeight: 32; implicitWidth: t.implicitWidth + 28; radius: 10
    color: accent ? (ma.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent) : (ma.containsMouse ? Theme.cardHigh : Theme.cardHigh)
    scale: ma.pressed ? 0.92 : (ma.containsMouse ? 1.07 : 1)
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 } }
    Text { id: t; anchors.centerIn: parent; textFormat: Text.PlainText; text: root.label
           color: root.accent ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11; font.bold: true }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
