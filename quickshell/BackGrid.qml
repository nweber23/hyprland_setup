import QtQuick

// Screen time, system monitor: a thin measuring grid with a scan line moving down it.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    Repeater {
        model: 9
        delegate: Rectangle { required property int index; x: index * root.width / 8; width: 1; height: root.height; color: Qt.alpha(root.tint, 0.07) }
    }
    Repeater {
        model: 12
        delegate: Rectangle { required property int index; y: index * root.height / 11; height: 1; width: root.width; color: Qt.alpha(root.tint, 0.07) }
    }
    Rectangle {
        id: scan
        width: root.width; height: 90
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.alpha(root.tint, 0.13) }
        }
        y: -height
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Qt.alpha(root.tint, 0.30) }
        SequentialAnimation on y { running: root.shown; loops: Animation.Infinite
            NumberAnimation { from: -90; to: root.height; duration: 5200; easing.type: Easing.InOutSine }
            PauseAnimation { duration: 900 } }
    }
}
