import QtQuick

// The drawing surface of the screenshot editor: the picture at its real size with the marks drawn over it.
// No Quickshell types in here, so it can be tested in a plain window. Shapes are plain objects:
// { type: "pen" | "marker" | "arrow" | "rect" | "cover" | "text", color, size, pts: [[x, y], ...], text }
Item {
    id: root
    property url source
    property string tool: "pen"
    property color color: "#ff3b30"
    property real size: 4                       // stroke width in picture pixels
    property var shapes: []
    onShapesChanged: cv.requestPaint()
    property var cur: null                      // the shape being drawn right now
    readonly property bool editingText: field.visible
    readonly property bool loaded: img.status === Image.Ready
    width: img.implicitWidth; height: img.implicitHeight

    function reset() { shapes = []; cur = null; field.visible = false; cv.requestPaint() }
    function undo() { if (field.visible) { field.visible = false; return } if (shapes.length > 0) { shapes = shapes.slice(0, -1); cv.requestPaint() } }
    function textPx(s) { return 14 + s * 4 }

    function drawShape(ctx, s) {
        const p = s.pts
        ctx.save()
        ctx.strokeStyle = s.color; ctx.fillStyle = s.color
        ctx.lineJoin = "round"; ctx.lineCap = "round"
        if (s.type === "pen" || s.type === "marker") {
            ctx.lineWidth = s.type === "marker" ? s.size * 4 : s.size
            if (s.type === "marker") { ctx.globalAlpha = 0.35; ctx.lineCap = "butt" }
            ctx.beginPath(); ctx.moveTo(p[0][0], p[0][1])
            if (p.length === 1) ctx.lineTo(p[0][0] + 0.1, p[0][1])
            for (let i = 1; i < p.length; i++) ctx.lineTo(p[i][0], p[i][1])
            ctx.stroke()
        } else if (p.length > 1 && s.type === "arrow") {
            ctx.lineWidth = s.size
            const a = Math.atan2(p[1][1] - p[0][1], p[1][0] - p[0][0]), h = s.size * 4 + 10
            ctx.beginPath(); ctx.moveTo(p[0][0], p[0][1]); ctx.lineTo(p[1][0] - Math.cos(a) * h * 0.6, p[1][1] - Math.sin(a) * h * 0.6); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(p[1][0], p[1][1])
            ctx.lineTo(p[1][0] - h * Math.cos(a - 0.4), p[1][1] - h * Math.sin(a - 0.4))
            ctx.lineTo(p[1][0] - h * Math.cos(a + 0.4), p[1][1] - h * Math.sin(a + 0.4))
            ctx.closePath(); ctx.fill()
        } else if (p.length > 1 && s.type === "rect") {
            ctx.lineWidth = s.size
            ctx.strokeRect(Math.min(p[0][0], p[1][0]), Math.min(p[0][1], p[1][1]), Math.abs(p[1][0] - p[0][0]), Math.abs(p[1][1] - p[0][1]))
        } else if (p.length > 1 && s.type === "cover") {   // solid black: a blur could be undone, this cannot
            ctx.fillStyle = "#000000"
            ctx.fillRect(Math.min(p[0][0], p[1][0]), Math.min(p[0][1], p[1][1]), Math.abs(p[1][0] - p[0][0]), Math.abs(p[1][1] - p[0][1]))
        } else if (s.type === "text") {
            ctx.font = "bold " + root.textPx(s.size) + "px sans-serif"; ctx.textBaseline = "top"
            ctx.fillText(s.text, p[0][0], p[0][1])
        }
        ctx.restore()
    }

    Image { id: img; source: root.source; cache: false; smooth: true }
    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            for (const s of root.shapes) root.drawShape(ctx, s)
            if (root.cur) root.drawShape(ctx, root.cur)
        }
    }

    // text: a click places a field, Enter commits it
    function commitText() {
        if (!field.visible) return
        field.visible = false
        if (field.text.trim() !== "") { shapes = shapes.concat([{ type: "text", color: String(field.color), size: size, pts: [[field.x, field.y]], text: field.text }]); cv.requestPaint() }
        field.text = ""
    }
    TextInput {
        id: field
        visible: false
        color: root.color
        font.family: "sans-serif"; font.bold: true; font.pixelSize: root.textPx(root.size)
        onAccepted: root.commitText()
        Keys.onEscapePressed: { field.visible = false; field.text = "" }
        onVisibleChanged: if (visible) forceActiveFocus()
        Rectangle { z: -1; anchors { fill: parent; margins: -4 } color: "transparent"; border.width: 1; border.color: Qt.alpha(root.color, 0.6) }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        onPressed: mouse => {
            if (root.tool === "text") { root.commitText(); field.text = ""; field.x = mouse.x; field.y = mouse.y; field.visible = true; return }
            root.commitText()
            root.cur = { type: root.tool, color: String(root.color), size: root.size, pts: [[mouse.x, mouse.y]] }
        }
        onPositionChanged: mouse => {
            if (!root.cur) return
            if (root.cur.type === "pen" || root.cur.type === "marker") root.cur.pts.push([mouse.x, mouse.y])
            else root.cur.pts = [root.cur.pts[0], [mouse.x, mouse.y]]
            cv.requestPaint()
        }
        onReleased: {
            if (!root.cur) return
            const c = root.cur; root.cur = null
            const moved = c.pts.length > 1 && Math.hypot(c.pts[c.pts.length - 1][0] - c.pts[0][0], c.pts[c.pts.length - 1][1] - c.pts[0][1]) > 3
            if (moved || c.type === "pen" || c.type === "marker") root.shapes = root.shapes.concat([c])
            cv.requestPaint()
        }
    }

    // saves the picture with the marks at its real size
    function exportPng(path, done) {
        commitText()
        grabToImage(r => done(r.saveToFile(path)), Qt.size(width, height))
    }
}
