import QtQuick
import QtQuick.Shapes

// Thin dashed line whose dashes travel along it while `flow` is on (the "live connection" look).
Shape {
    id: root
    property real x1: 0
    property real y1: 0
    property real x2: 0
    property real y2: 0
    property bool flow: false
    property color tone: Theme.accent
    property real off: 0
    layer.enabled: true; layer.samples: 4
    NumberAnimation on off { running: root.flow; loops: Animation.Infinite; from: 0; to: -7; duration: 900 }
    ShapePath {
        strokeColor: Qt.alpha(root.tone, 0.5); strokeWidth: 1.5; fillColor: "transparent"
        strokeStyle: ShapePath.DashLine; dashPattern: [3, 4]; dashOffset: root.off
        startX: root.x1; startY: root.y1
        PathLine { x: root.x2; y: root.y2 }
    }
}
