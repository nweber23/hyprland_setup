import QtQuick
import QtQuick.Shapes

// Ring gauge, value 0..1, starts at the top.
Item {
    id: root
    property real value: 0
    property real thickness: 12
    property color color: Theme.accent
    property color trackColor: Theme.cardHigh
    implicitWidth: 200; implicitHeight: 200
    readonly property real r: (Math.min(width, height) - thickness) / 2

    Shape {
        anchors.fill: parent
        layer.enabled: true; layer.samples: 4
        ShapePath {
            strokeColor: root.trackColor; strokeWidth: root.thickness; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: root.width / 2; centerY: root.height / 2; radiusX: root.r; radiusY: root.r; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {
            strokeColor: root.color; strokeWidth: root.thickness; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2; radiusX: root.r; radiusY: root.r
                startAngle: -90; sweepAngle: 360 * Math.max(0.001, Math.min(1, root.value))
                Behavior on sweepAngle { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }
    }
}
