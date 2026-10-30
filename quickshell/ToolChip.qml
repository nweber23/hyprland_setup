import QtQuick

// Small text chip for the tools panel.
Rectangle {
    id: c
    property string label: ""
    property bool on: false
    signal clicked()
    implicitHeight: 30; implicitWidth: t.implicitWidth + 24; radius: 10
    color: on ? Theme.accent : (cm.containsMouse ? Theme.cardHigh : Theme.card)
    Behavior on color { ColorAnimation { duration: 150 } }
    Text { id: t; anchors.centerIn: parent; textFormat: Text.PlainText; text: c.label
           color: c.on ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11; font.bold: true }
    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: c.clicked() }
}
