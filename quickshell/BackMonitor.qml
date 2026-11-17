import QtQuick

// Display: a monitor with a sun that brightens and dims on its screen.
BackBase {
    draw: (c, w, h, t, r) => {
        const sw = w * 0.78, sh = sw * 0.58, sx = (w - sw) / 2, sy = h * 0.2
        const b = 0.5 + 0.5 * Math.sin(t * 0.9)
        c.fillStyle = r.p(0.08 + 0.05 * b); c.beginPath(); c.roundedRect(sx, sy, sw, sh, 18, 18); c.fill()
        c.strokeStyle = r.p(0.3); c.lineWidth = 4; c.beginPath(); c.roundedRect(sx, sy, sw, sh, 18, 18); c.stroke()
        c.fillStyle = r.p(0.2); c.beginPath(); c.moveTo(w / 2 - 14, sy + sh + 2); c.lineTo(w / 2 + 14, sy + sh + 2); c.lineTo(w / 2 + 30, sy + sh + 40); c.lineTo(w / 2 - 30, sy + sh + 40); c.closePath(); c.fill()
        c.beginPath(); c.roundedRect(w / 2 - 56, sy + sh + 38, 112, 9, 4.5, 4.5); c.fill()
        const mx = w / 2, my = sy + sh / 2, rr = sh * 0.14 * (0.9 + 0.2 * b)
        c.fillStyle = r.t3(0.2 + 0.3 * b); c.beginPath(); r.circle(c, mx, my, rr); c.fill()
        c.strokeStyle = r.t3(0.2 + 0.35 * b); c.lineWidth = 4; c.lineCap = "round"; c.beginPath()
        for (let i = 0; i < 8; i++) { const a = i * 0.7854, l = rr * (1.5 + 0.35 * b); c.moveTo(mx + Math.cos(a) * rr * 1.3, my + Math.sin(a) * rr * 1.3); c.lineTo(mx + Math.cos(a) * l, my + Math.sin(a) * l) }
        c.stroke()
    }
}
