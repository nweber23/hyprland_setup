import QtQuick

// Fully solid play / pause glyph.
Canvas {
    property bool playing: false
    property real size: 20
    property color color: Theme.on_surface
    width: size; height: size
    onColorChanged: requestPaint()
    onPlayingChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"), s = width
        c.reset(); c.fillStyle = color; c.strokeStyle = color; c.lineJoin = "round"
        if (playing) {
            c.beginPath(); c.roundedRect(s * 0.2, s * 0.16, s * 0.22, s * 0.68, s * 0.07, s * 0.07); c.fill()
            c.beginPath(); c.roundedRect(s * 0.58, s * 0.16, s * 0.22, s * 0.68, s * 0.07, s * 0.07); c.fill()
        } else {
            c.beginPath(); c.moveTo(s * 0.26, s * 0.16); c.lineTo(s * 0.84, s * 0.5); c.lineTo(s * 0.26, s * 0.84); c.closePath(); c.fill()
            c.lineWidth = s * 0.1; c.stroke()
        }
    }
}
