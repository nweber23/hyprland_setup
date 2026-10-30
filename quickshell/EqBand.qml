import QtQuick

// Vertical slider for one equalizer band. value in dB, -range..+range, fills from the centre line.
Item {
    id: root
    property real value: 0
    property real range: 12
    property string label: ""
    signal moved(real db)
    implicitWidth: 26
    implicitHeight: 150

    readonly property real trackH: height - 22
    Rectangle {
        id: track
        x: (parent.width - 8) / 2; width: 8; height: root.trackH; radius: 4
        color: Theme.surface_container_high
        Rectangle {   // zero line
            width: parent.width + 6; x: -3; height: 1; y: parent.height / 2
            color: Theme.outline_variant
        }
        Rectangle {   // fill from the centre to the value
            width: parent.width; radius: 4
            color: Theme.primary
            readonly property real h: Math.abs(root.value) / root.range * (parent.height / 2)
            height: Math.max(2, h)
            y: root.value >= 0 ? parent.height / 2 - h : parent.height / 2
            Behavior on height { enabled: !area.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: !area.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
        Rectangle {   // knob
            width: 16; height: 16; radius: 8; x: (parent.width - width) / 2
            y: (1 - (root.value + root.range) / (2 * root.range)) * (parent.height - height)
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
        font.family: "JetBrains Mono"; font.pixelSize: 9
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
