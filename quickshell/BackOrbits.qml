import QtQuick

// Settings, tools: thin orbit lines in the lower right corner with a small dot circling on each.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    Repeater {
        model: [
            { r: 110, dur: 24000, dir: 1 },
            { r: 190, dur: 36000, dir: -1 },
            { r: 280, dur: 52000, dir: 1 },
            { r: 380, dur: 74000, dir: -1 }
        ]
        delegate: Item {
            id: orbit
            required property var modelData
            width: modelData.r * 2; height: width
            x: root.width * 0.92 - width / 2; y: root.height * 0.94 - height / 2
            Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.width: 1; border.color: Qt.alpha(root.tint, 0.09) }
            Item {   // turns; the dot sits on its top edge
                anchors.fill: parent
                RotationAnimation on rotation { running: root.shown; loops: Animation.Infinite; from: 0; to: 360 * orbit.modelData.dir; duration: orbit.modelData.dur }
                Rectangle { width: 7; height: 7; radius: 3.5; color: Qt.alpha(root.tint, 0.30); anchors.horizontalCenter: parent.horizontalCenter; y: -3.5 }
            }
        }
    }
}
