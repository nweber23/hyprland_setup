import QtQuick

// Volume: slim bars at the bottom that rise and fall like an equaliser, slowly.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    readonly property int n: 26
    function r(i, k) { const x = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453; return x - Math.floor(x) }
    Repeater {
        model: root.n
        delegate: Rectangle {
            id: bar
            required property int index
            readonly property real hi: root.height * (0.14 + 0.26 * root.r(index, 1))
            readonly property real lo: root.height * (0.03 + 0.05 * root.r(index, 2))
            width: root.width / root.n * 0.56; radius: 3
            x: (index + 0.22) * root.width / root.n
            y: root.height - height
            height: lo
            color: Qt.alpha(root.tint, 0.09 + 0.05 * root.r(index, 3))
            SequentialAnimation on height { running: root.shown; loops: Animation.Infinite
                NumberAnimation { to: bar.hi; duration: 1800 + 2200 * root.r(bar.index, 4); easing.type: Easing.InOutSine }
                NumberAnimation { to: bar.lo; duration: 1800 + 2200 * root.r(bar.index, 5); easing.type: Easing.InOutSine } }
        }
    }
}
