import QtQuick

// Minimal pill slider, value in 0..1. Emits moved(v) while the user drags.
Item {
    id: root
    property real value: 0
    signal moved(real v)
    implicitHeight: 26
    implicitWidth: 200

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 12; radius: 6
        color: Theme.surface_container_high
        Rectangle {
            width: Math.max(12, parent.width * root.value); height: parent.height; radius: 6
            color: Theme.primary
            Behavior on width { enabled: !area.pressed; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        function setFrom(x) { root.moved(Math.max(0, Math.min(1, x / width))) }
        onPressed: mouse => setFrom(mouse.x)
        onPositionChanged: mouse => { if (pressed) setFrom(mouse.x) }
    }
}
