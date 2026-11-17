import QtQuick

// Panel backdrop base: a 2D canvas redrawn at ~30 fps while the panel is open.
// Each Back*.qml supplies `draw(c, w, h, t, r)`: c is the 2D context, t the seconds of open time, r this item.
// Colours come from the theme: r.p(a) primary, r.t3(a) tertiary, r.s(a) secondary, each with alpha a.
Item {
    id: root
    property bool shown: false
    property var draw: null
    property real t: 0
    anchors.fill: parent
    function rgba(col, a) { return "rgba(" + Math.round(col.r * 255) + "," + Math.round(col.g * 255) + "," + Math.round(col.b * 255) + "," + a + ")" }
    function p(a) { return rgba(Theme.primary, a) }
    function t3(a) { return rgba(Theme.tertiary, a) }
    function s(a) { return rgba(Theme.secondary, a) }
    function circle(c, x, y, rad) { c.moveTo(x + rad, y); c.arc(x, y, rad, 0, 6.2832) }
    function smooth(x) { x = Math.max(0, Math.min(1, x)); return x * x * (3 - 2 * x) }

    property real last: 0
    Timer {
        interval: 33; repeat: true; running: root.shown
        onRunningChanged: if (running) root.last = Date.now()
        onTriggered: { const n = Date.now(); root.t += (n - root.last) / 1000; root.last = n; cv.requestPaint() }
    }
    Canvas {
        id: cv
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        onPaint: { const c = getContext("2d"); c.clearRect(0, 0, width, height); if (root.draw) root.draw(c, width, height, root.t, root) }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
    Connections { target: Theme; function onPrimaryChanged() { cv.requestPaint() } }
}
