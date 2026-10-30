import QtQuick
import QtQuick.Layouts

// Small info card around a node: icon, value and label. Pops in after `delay` ms once `shown` turns on.
Rectangle {
    id: c
    property string icon: ""
    property string value: ""
    property string label: ""
    property bool shown: false
    property int delay: 0
    implicitWidth: 156; implicitHeight: 52
    radius: 11; color: Theme.card; border.width: 1; border.color: Theme.cardHigh

    property real appear: 0
    onShownChanged: if (shown) pop.restart(); else { pop.stop(); appear = 0 }
    Component.onCompleted: if (shown) pop.restart()   // created while already open (e.g. the data changed)
    SequentialAnimation { id: pop
        PauseAnimation { duration: c.delay }
        NumberAnimation { target: c; property: "appear"; from: 0; to: 1; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
    opacity: Math.min(1, appear * 1.8)
    scale: 0.7 + 0.3 * appear

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
        spacing: 10
        Icon { name: c.icon; size: 20; color: Theme.accent }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 0
            Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: c.value
                   color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12; font.bold: true }
            Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: c.label
                   color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 9 }
        }
    }
}
