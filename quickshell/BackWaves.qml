import QtQuick
import QtQuick.Shapes

// Music: three soft sine waves drifting sideways. The path is built once and slid, so it costs the GPU only.
Item {
    id: root
    property bool shown: false
    property color tint: Theme.accent
    anchors.fill: parent
    Repeater {
        model: [
            { amp: 14, n: 2, ph: 0.0, y: 0.60, a: 0.16, speed: 16000, w: 2 },
            { amp: 22, n: 1, ph: 1.6, y: 0.72, a: 0.11, speed: 23000, w: 2 },
            { amp: 10, n: 3, ph: 3.1, y: 0.84, a: 0.09, speed: 12000, w: 1.5 }
        ]
        delegate: Shape {
            id: wave
            required property var modelData
            width: root.width * 2; height: root.height
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: wave.modelData.w
                strokeColor: Qt.alpha(root.tint, wave.modelData.a)
                fillColor: "transparent"
                PathPolyline {
                    path: {
                        const pts = [], W = Math.max(1, root.width)
                        for (let x = 0; x <= W * 2; x += 6)   // a whole number of periods per panel width: the loop is seamless
                            pts.push(Qt.point(x, root.height * wave.modelData.y + wave.modelData.amp * Math.sin(2 * Math.PI * wave.modelData.n * x / W + wave.modelData.ph)))
                        return pts
                    }
                }
            }
            NumberAnimation on x { running: root.shown; from: 0; to: -root.width; duration: wave.modelData.speed; loops: Animation.Infinite }
        }
    }
}
