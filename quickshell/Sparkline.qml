import QtQuick

// Smooth area chart of the last samples that glides to the left whenever a new one arrives.
Canvas {
    id: root
    property var values: []
    property real maxValue: 100
    property color tone: Theme.accent
    property int tick: 0                 // changes on every new sample
    property real shift: 0               // 1 -> 0 right after a sample: the chart slides in
    onTickChanged: slide.restart()
    NumberAnimation { id: slide; target: root; property: "shift"; from: 1; to: 0; duration: 900; easing.type: Easing.OutCubic }
    onShiftChanged: requestPaint()
    onValuesChanged: requestPaint()
    renderStrategy: Canvas.Cooperative
    onPaint: {
        const c = getContext("2d"); c.reset()
        const n = 60, step = width / (n - 2)
        const v = values.length ? values : [0]
        const pts = []
        for (let i = 0; i < v.length; i++) {
            const k = n - v.length + i                          // newest sample sits at the right edge
            pts.push({ x: (k - 1 + (1 - shift)) * step - step + step, y: height - 4 - Math.min(1, v[i] / maxValue) * (height - 10) })
        }
        if (pts.length < 2) return
        c.beginPath(); c.moveTo(pts[0].x, pts[0].y)
        for (let i = 1; i < pts.length; i++) { const mx = (pts[i - 1].x + pts[i].x) / 2; c.bezierCurveTo(mx, pts[i - 1].y, mx, pts[i].y, pts[i].x, pts[i].y) }
        c.strokeStyle = tone; c.lineWidth = 2; c.stroke()
        c.lineTo(pts[pts.length - 1].x, height); c.lineTo(pts[0].x, height); c.closePath()
        const g = c.createLinearGradient(0, 0, 0, height)
        g.addColorStop(0, Qt.rgba(tone.r, tone.g, tone.b, 0.35)); g.addColorStop(1, Qt.rgba(tone.r, tone.g, tone.b, 0))
        c.fillStyle = g; c.fill()
    }
}
