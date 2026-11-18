import QtQuick

// Fully solid skip glyph (triangle + bar), drawn by hand because the font's version is only half filled.
Canvas {
    property bool next: true
    property real size: 20
    property color color: Theme.on_surface
    width: size; height: size
    onColorChanged: requestPaint()
    onNextChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"), s = width
        c.reset(); c.fillStyle = color
        if (!next) { c.translate(s, 0); c.scale(-1, 1) }
        const bw = s * 0.16, r = bw / 2
        c.beginPath(); c.moveTo(s * 0.18, s * 0.2); c.lineTo(s * 0.74, s * 0.5); c.lineTo(s * 0.18, s * 0.8); c.closePath(); c.fill()
        c.lineJoin = "round"; c.lineWidth = s * 0.08; c.strokeStyle = color; c.stroke()
        c.beginPath(); c.roundedRect(s * 0.74, s * 0.2, bw, s * 0.6, r, r); c.fill()
    }
}
