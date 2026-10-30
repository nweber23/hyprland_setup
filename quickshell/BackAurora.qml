import QtQuick

// Display: wide, very faint light bands without hard edges, so the text on top stays readable.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    Repeater {
        model: [
            { y: 0.18, dx: 60,  dur: 14000, rot: -14 },
            { y: 0.52, dx: -80, dur: 19000, rot: -10 },
            { y: 0.84, dx: 50,  dur: 16000, rot: -16 }
        ]
        delegate: Item {
            id: band
            required property var modelData
            width: root.width * 1.5; height: 150
            x: -root.width * 0.25; y: root.height * modelData.y - height / 2
            rotation: modelData.rot
            Repeater {   // layers of different thickness: the edges fade out softly
                model: 5
                delegate: Rectangle {
                    required property int index
                    anchors.centerIn: parent
                    width: parent.width; height: 150 * (1 - index * 0.19); radius: height / 2
                    color: Qt.alpha(root.tint, 0.012)
                }
            }
            SequentialAnimation on x { running: root.shown; loops: Animation.Infinite
                NumberAnimation { to: -root.width * 0.25 + band.modelData.dx; duration: band.modelData.dur; easing.type: Easing.InOutSine }
                NumberAnimation { to: -root.width * 0.25; duration: band.modelData.dur; easing.type: Easing.InOutSine } }
        }
    }
}
