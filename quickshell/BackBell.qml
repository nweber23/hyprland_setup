import QtQuick

// Notifications: a bell swinging in the corner with ripples either side.
BackBase {
    draw: (c, w, h, t, r) => {
        const px = w * 0.78, py = h * 0.06, s = 72
        const swing = 0.2 * Math.sin(t * 2.2) * (0.5 + 0.5 * Math.sin(t * 0.55))
        for (let i = 0; i < 2; i++) {
            const p = (t / 6 + i / 2) % 1, q = s * (1.3 + 1.4 * p)
            c.strokeStyle = r.t3(0.3 * (1 - p)); c.lineWidth = 2
            c.beginPath(); c.arc(px, py + s * 0.6, q, 2.5, 3.9); c.stroke()
            c.beginPath(); c.arc(px, py + s * 0.6, q, -0.76, 0.64); c.stroke()
        }
        c.save(); c.translate(px, py); c.rotate(swing)
        c.fillStyle = r.p(0.2)
        c.beginPath()
        c.moveTo(-0.95 * s, 1.05 * s)
        c.bezierCurveTo(-0.55 * s, 0.95 * s, -0.62 * s, 0.25 * s, -0.5 * s, -0.05 * s)
        c.bezierCurveTo(-0.4 * s, -0.5 * s, 0.4 * s, -0.5 * s, 0.5 * s, -0.05 * s)
        c.bezierCurveTo(0.62 * s, 0.25 * s, 0.55 * s, 0.95 * s, 0.95 * s, 1.05 * s)
        c.closePath(); c.fill()
        c.fillStyle = r.t3(0.4); c.beginPath(); r.circle(c, 0, -0.5 * s, 0.09 * s); c.fill()
        c.beginPath(); r.circle(c, 0, 1.28 * s + 4 * Math.sin(t * 2.2 + 1), 0.16 * s); c.fill()
        c.restore()
    }
}
