import QtQuick

// Notifications: small flecks drifting down, like dust or snow.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    function r(i, k) { const x = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453; return x - Math.floor(x) }
    Repeater {
        model: 18
        delegate: Rectangle {
            id: p
            required property int index
            readonly property real dur: 14000 + 12000 * root.r(index, 2)
            width: 3 + 3 * root.r(index, 1); height: width; radius: width / 2
            x: root.r(index, 4) * root.width
            y: root.height * root.r(index, 3)
            color: Qt.alpha(root.tint, 0.32)
            SequentialAnimation on y { running: root.shown
                NumberAnimation { to: root.height; duration: p.dur * (1 - p.y / root.height) }
                SequentialAnimation { loops: Animation.Infinite
                    NumberAnimation { from: -p.height; to: root.height; duration: p.dur } } }
            SequentialAnimation on x { running: root.shown; loops: Animation.Infinite
                NumberAnimation { to: p.x + 18; duration: 4000 + 2000 * root.r(p.index, 5); easing.type: Easing.InOutSine }
                NumberAnimation { to: p.x - 18; duration: 4000 + 2000 * root.r(p.index, 6); easing.type: Easing.InOutSine } }
        }
    }
}
