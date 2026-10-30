import QtQuick

// Calendar: a fine dot grid with a soft light wandering across it.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    readonly property int cols: 14
    readonly property int rows: 16
    Repeater {
        model: root.cols * root.rows
        delegate: Rectangle {
            required property int index
            width: 3; height: 3; radius: 1.5
            x: (index % root.cols + 0.5) * root.width / root.cols - 1.5
            y: (Math.floor(index / root.cols) + 0.5) * root.height / root.rows - 1.5
            color: Qt.alpha(root.tint, 0.12)
        }
    }
    Item {   // the light: stacked translucent discs fall off softly, no blur pass needed
        id: glow
        width: 260; height: 260
        x: -80; y: root.height * 0.2
        Repeater {
            model: 7
            delegate: Rectangle {
                required property int index
                anchors.centerIn: parent
                width: 260 * (1 - index * 0.13); height: width; radius: width / 2
                color: Qt.alpha(root.tint, 0.028)
            }
        }
        SequentialAnimation on x { running: root.shown; loops: Animation.Infinite
            NumberAnimation { to: root.width - 180; duration: 9000; easing.type: Easing.InOutSine }
            NumberAnimation { to: -80; duration: 9000; easing.type: Easing.InOutSine } }
        SequentialAnimation on y { running: root.shown; loops: Animation.Infinite
            NumberAnimation { to: root.height * 0.7; duration: 7000; easing.type: Easing.InOutSine }
            NumberAnimation { to: root.height * 0.1; duration: 7000; easing.type: Easing.InOutSine } }
    }
}
