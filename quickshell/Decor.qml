import QtQuick

// Big, barely visible circles behind panel content. They drift slowly while the panel is open.
// Parent is expected to clip.
Item {
    id: root
    property color tint: Theme.accent
    property bool shown: false
    anchors.fill: parent
    Rectangle {
        id: c1
        x: root.width * 0.30; y: -root.height * 0.15; width: root.height * 1.15; height: width; radius: width / 2
        color: Qt.alpha(root.tint, 0.045)
        SequentialAnimation on scale { running: root.shown; loops: Animation.Infinite
            NumberAnimation { to: 1.06; duration: 5200; easing.type: Easing.InOutSine } NumberAnimation { to: 1.0; duration: 5200; easing.type: Easing.InOutSine } }
    }
    Rectangle {
        id: c2
        x: root.width * 0.55; y: root.height * 0.20; width: root.height * 0.95; height: width; radius: width / 2
        color: Qt.alpha(root.tint, 0.04)
        SequentialAnimation on x { running: root.shown; loops: Animation.Infinite
            NumberAnimation { to: root.width * 0.50; duration: 7000; easing.type: Easing.InOutSine } NumberAnimation { to: root.width * 0.57; duration: 7000; easing.type: Easing.InOutSine } }
    }
    Rectangle {
        id: c3
        x: -root.width * 0.10; y: root.height * 0.45; width: root.height * 0.8; height: width; radius: width / 2
        color: Qt.alpha(root.tint, 0.03)
        SequentialAnimation on y { running: root.shown; loops: Animation.Infinite
            NumberAnimation { to: root.height * 0.40; duration: 6200; easing.type: Easing.InOutSine } NumberAnimation { to: root.height * 0.5; duration: 6200; easing.type: Easing.InOutSine } }
    }
}
