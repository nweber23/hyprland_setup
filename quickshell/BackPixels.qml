import QtQuick

// Display: a coarse pixel grid whose cells flicker on and off.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    readonly property int cols: 10
    readonly property int rows: 12
    function r(i, k) { const x = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453; return x - Math.floor(x) }
    Repeater {
        model: root.cols * root.rows
        delegate: Rectangle {
            id: px
            required property int index
            readonly property bool live: root.r(index, 1) > 0.55   // only some cells flicker
            width: root.width / root.cols - 8; height: width * 0.62; radius: 3
            x: (index % root.cols) * root.width / root.cols + 4
            y: Math.floor(index / root.cols) * root.height / root.rows + 6
            color: root.tint
            opacity: 0.03
            SequentialAnimation on opacity { running: root.shown && px.live; loops: Animation.Infinite
                NumberAnimation { to: 0.16; duration: 700 + 1800 * root.r(px.index, 2); easing.type: Easing.InOutSine }
                PauseAnimation { duration: 300 * root.r(px.index, 3) }
                NumberAnimation { to: 0.03; duration: 700 + 1800 * root.r(px.index, 4); easing.type: Easing.InOutSine } }
        }
    }
}
