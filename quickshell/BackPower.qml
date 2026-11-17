import QtQuick

// Power: a big power symbol breathing slowly, a spark circling it.
BackBase {
    draw: (c, w, h, t, r) => {
        const cx = w / 2, cy = h * 0.56, R = Math.min(w * 0.34, h * 0.24), gap = 0.62, b = 0.5 + 0.5 * Math.sin(t * 1.1)
        c.lineCap = "round"; c.lineWidth = 16
        c.strokeStyle = r.p(0.12 + 0.07 * b)
        c.beginPath(); c.arc(cx, cy, R, -1.5708 + gap, -1.5708 + 6.2832 - gap); c.stroke()
        c.beginPath(); c.moveTo(cx, cy - R * 1.12); c.lineTo(cx, cy - R * 0.1); c.stroke()
        c.lineWidth = 2; c.strokeStyle = r.p(0.12); c.beginPath(); c.arc(cx, cy, R + 36, 0, 6.2832); c.stroke()
        const a = t * 0.7
        c.lineWidth = 3; c.strokeStyle = r.t3(0.5); c.beginPath(); c.arc(cx, cy, R + 36, a, a + 0.45); c.stroke()
        c.fillStyle = r.t3(0.8); c.beginPath(); r.circle(c, cx + Math.cos(a + 0.45) * (R + 36), cy + Math.sin(a + 0.45) * (R + 36), 4); c.fill()
    }
}
