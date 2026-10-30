import QtQuick

// Vertical slider for one equalizer band. value in dB, -range..+range (0 dB in the middle), fills from the bottom.
Item {
    id: root
    property real value: 0
    property real range: 12
    property string label: ""
    signal moved(real db)
    implicitWidth: 26
    implicitHeight: 150

    readonly property real trackH: height - 20
    readonly property real frac: (value + range) / (2 * range)
    Rectangle {
        id: track
        x: (parent.width - 8) / 2; width: 8; height: root.trackH; radius: 4
        color: Theme.cardHigh
        Rectangle {   // fill from the bottom up to the knob
            width: parent.width; radius: 4; color: Theme.accent2
            height: Math.max(8, root.frac * parent.height)
            anchors.bottom: parent.bottom
            Behavior on height { enabled: !area.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
        Rectangle {   // knob
            width: 16; height: 16; radius: 8; x: (parent.width - width) / 2
            y: (1 - root.frac) * (parent.height - height)
            color: Theme.on_surface
            scale: area.pressed ? 1.2 : 1
            Behavior on scale { NumberAnimation { duration: 120 } }
            Behavior on y { enabled: !area.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
    }
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
        textFormat: Text.PlainText
        text: root.label
        color: Theme.on_surface_variant
        font.family: Theme.mono; font.pixelSize: 9
    }
    MouseArea {
        id: area
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.trackH
        function setFrom(y) {
            const t = Math.max(0, Math.min(1, (y - 8) / (height - 16)))
            root.moved((1 - t) * 2 * root.range - root.range)
        }
        onPressed: mouse => setFrom(mouse.y)
        onPositionChanged: mouse => { if (pressed) setFrom(mouse.y) }
        onDoubleClicked: root.moved(0)
    }
}
