import QtQuick

// Thick pill slider, value in 0..1. Emits moved(v) while the user drags.
Item {
    id: root
    property real value: 0
    property color fill: Theme.accent
    property bool knob: false
    signal moved(real v)
    implicitHeight: knob ? 24 : 18
    implicitWidth: 200

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 14; radius: 7
        color: Theme.cardHigh
        Rectangle {
            width: Math.max(14, parent.width * root.value); height: parent.height; radius: 7
            color: root.fill
            Behavior on width { enabled: !area.pressed; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
        Rectangle {
            visible: root.knob
            width: 22; height: 22; radius: 11
            x: Math.max(0, Math.min(parent.width - width, parent.width * root.value - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.on_surface
            Behavior on x { enabled: !area.pressed; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
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
