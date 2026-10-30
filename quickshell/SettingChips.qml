import QtQuick

// Segmented selector with a sliding highlight. model: [{ label, value }]. Emits picked(value).
Rectangle {
    id: root
    property var model: []
    property var current
    property int chipW: 78
    signal picked(var value)
    implicitWidth: model.length * chipW + (model.length - 1) * 4 + 8
    implicitHeight: 34; radius: 11; color: Theme.card
    readonly property int index: { for (let i = 0; i < model.length; i++) if (model[i].value === current) return i; return -1 }
    Rectangle {
        visible: root.index >= 0
        width: root.chipW; height: 26; radius: 8; y: 4; color: Theme.accent
        x: 4 + Math.max(0, root.index) * (root.chipW + 4)
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
    }
    Row {
        x: 4; y: 4; spacing: 4
        Repeater {
            model: root.model
            delegate: Item {
                required property var modelData
                required property int index
                width: root.chipW; height: 26
                Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData.label
                       color: root.index === index ? Theme.panelBg : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11; font.bold: true
                       Behavior on color { ColorAnimation { duration: 200 } } }
                MouseArea { anchors.fill: parent; onClicked: root.picked(modelData.value) }
            }
        }
    }
}
