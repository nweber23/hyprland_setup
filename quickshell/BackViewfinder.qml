import QtQuick

// Screenshot and recording: a camera viewfinder, corner brackets that breathe and a faint crosshair.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    property real inset: 22
    SequentialAnimation on inset { running: root.shown; loops: Animation.Infinite
        NumberAnimation { to: 36; duration: 2600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 22; duration: 2600; easing.type: Easing.InOutSine } }
    Repeater {
        model: [{ ax: 0, ay: 0 }, { ax: 1, ay: 0 }, { ax: 0, ay: 1 }, { ax: 1, ay: 1 }]
        delegate: Item {
            required property var modelData
            width: 40; height: 40
            x: modelData.ax ? root.width - root.inset - width : root.inset
            y: modelData.ay ? root.height - root.inset - height : root.inset
            Rectangle { width: parent.width; height: 2; radius: 1; y: modelData.ay ? parent.height - 2 : 0; color: Qt.alpha(root.tint, 0.26) }
            Rectangle { width: 2; height: parent.height; radius: 1; x: modelData.ax ? parent.width - 2 : 0; color: Qt.alpha(root.tint, 0.26) }
        }
    }
    Rectangle { width: 1; height: 26; x: root.width / 2; y: root.height / 2 - 13; color: Qt.alpha(root.tint, 0.18) }
    Rectangle { width: 26; height: 1; x: root.width / 2 - 13; y: root.height / 2; color: Qt.alpha(root.tint, 0.18) }
    Rectangle {
        width: 8; height: 8; radius: 4; color: Qt.alpha(Theme.error, 0.0)
        x: root.width - root.inset - 74; y: root.inset + 6
        SequentialAnimation on color { running: root.shown; loops: Animation.Infinite
            ColorAnimation { to: Qt.alpha(Theme.error, 0.45); duration: 900 }
            ColorAnimation { to: Qt.alpha(Theme.error, 0.0); duration: 900 } }
    }
}
