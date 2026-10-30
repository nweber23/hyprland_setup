import QtQuick

// Power: bubbles rising from the bottom, like in a liquid.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    function r(i, k) { const x = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453; return x - Math.floor(x) }
    Repeater {
        model: 13
        delegate: Rectangle {
            id: b
            required property int index
            readonly property real dur: 9000 + 8000 * root.r(index, 2)
            readonly property real start: root.r(index, 3)
            width: 8 + 26 * root.r(index, 1); height: width; radius: width / 2
            x: root.r(index, 4) * (root.width - width)
            y: root.height * (0.2 + 0.8 * start)
            color: Qt.alpha(root.tint, 0.07)
            border.width: 1; border.color: Qt.alpha(root.tint, 0.16)
            SequentialAnimation on y { running: root.shown
                NumberAnimation { to: -b.height; duration: b.dur * (b.y + b.height) / (root.height + b.height) }
                SequentialAnimation { loops: Animation.Infinite
                    NumberAnimation { from: root.height; to: -b.height; duration: b.dur } } }
            SequentialAnimation on x { running: root.shown; loops: Animation.Infinite
                NumberAnimation { to: b.x + 16; duration: 3200; easing.type: Easing.InOutSine }
                NumberAnimation { to: b.x - 16; duration: 3200; easing.type: Easing.InOutSine } }
        }
    }
}
