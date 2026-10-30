import QtQuick

// Network: rings spreading out from the centre like a radio signal.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    property real t: 0
    NumberAnimation on t { running: root.shown; from: 0; to: 1; duration: 7200; loops: Animation.Infinite }
    Repeater {
        model: 4
        delegate: Rectangle {
            id: ring
            required property int index
            readonly property real p: (root.t + index / 4) % 1
            width: root.height * 1.25; height: width; radius: width / 2
            x: root.width * 0.5 - width / 2; y: root.height * 0.30 - height / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.alpha(root.tint, 0.20)
            scale: 0.12 + 1.0 * p
            opacity: (1 - p) * Math.min(1, p * 6)
        }
    }
    Rectangle {   // the source
        width: 14; height: 14; radius: 7; color: Qt.alpha(root.tint, 0.28)
        x: root.width * 0.5 - 7; y: root.height * 0.30 - 7
    }
}
