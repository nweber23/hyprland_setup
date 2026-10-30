import QtQuick

// Settings, tools: two big gear outlines turning slowly against each other.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    Repeater {
        model: [
            { size: 330, fx: 0.80, fy: 0.78, teeth: 14, dir: 1,  dur: 60000 },
            { size: 190, fx: 0.10, fy: 0.12, teeth: 10, dir: -1, dur: 36000 }
        ]
        delegate: Item {
            id: gear
            required property var modelData
            width: modelData.size; height: width
            x: root.width * modelData.fx - width / 2; y: root.height * modelData.fy - height / 2
            RotationAnimation on rotation { running: root.shown; loops: Animation.Infinite
                from: 0; to: 360 * gear.modelData.dir; duration: gear.modelData.dur }
            Repeater {
                model: gear.modelData.teeth
                delegate: Item {
                    required property int index
                    anchors.fill: parent
                    rotation: index * 360 / gear.modelData.teeth
                    Rectangle { width: gear.width * 0.14; height: gear.width * 0.10; radius: 3
                                anchors.horizontalCenter: parent.horizontalCenter; y: 0
                                color: Qt.alpha(root.tint, 0.09) }
                }
            }
            Rectangle { anchors { fill: parent; margins: gear.width * 0.08 } radius: width / 2
                        color: "transparent"; border.width: 3; border.color: Qt.alpha(root.tint, 0.10) }
            Rectangle { anchors { fill: parent; margins: gear.width * 0.34 } radius: width / 2
                        color: "transparent"; border.width: 2; border.color: Qt.alpha(root.tint, 0.08) }
        }
    }
}
