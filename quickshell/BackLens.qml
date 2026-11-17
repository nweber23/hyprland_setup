import QtQuick

// Capture: a camera iris opening and closing, corner brackets, a lens glint.
BackBase {
    draw: (c, w, h, t, r) => {
        const cx = w / 2, cy = h * 0.6, R = Math.min(w * 0.42, h * 0.3), open = 0.5 + 0.5 * Math.sin(t * 0.9)
        const r0 = R * (0.22 + 0.4 * open), rot = t * 0.12
        c.fillStyle = r.p(0.07); c.beginPath(); r.circle(c, cx, cy, R * 1.12); c.fill()
        c.strokeStyle = r.p(0.28); c.lineWidth = 8; c.beginPath(); c.arc(cx, cy, R * 1.12, 0, 6.2832); c.stroke()
        c.lineWidth = 2; c.strokeStyle = r.p(0.18); c.beginPath(); c.arc(cx, cy, R * 1.0, 0, 6.2832); c.stroke()
        for (let k = 0; k < 6; k++) {
            const a = rot + k * 1.0472, b = a + 1.0472, tw = 0.35
            c.fillStyle = r.p(0.1 + 0.03 * (k % 2)); c.strokeStyle = r.p(0.26); c.lineWidth = 1.5
            c.beginPath()
            c.moveTo(cx + Math.cos(a) * R, cy + Math.sin(a) * R)
            c.arc(cx, cy, R, a, b)
            c.lineTo(cx + Math.cos(b + tw) * r0, cy + Math.sin(b + tw) * r0)
            c.lineTo(cx + Math.cos(a + tw) * r0, cy + Math.sin(a + tw) * r0)
            c.closePath(); c.fill(); c.stroke()
        }
        c.fillStyle = r.t3(0.4); c.beginPath(); r.circle(c, cx - R * 0.55, cy - R * 0.5, 6); c.fill()
        c.fillStyle = r.t3(0.18); c.beginPath(); r.circle(c, cx - R * 0.55, cy - R * 0.5, 16); c.fill()
        const k = 20, L = 26; c.lineWidth = 3; c.lineCap = "round"; c.strokeStyle = r.t3(0.4)
        c.beginPath()
        c.moveTo(k, k + L); c.lineTo(k, k); c.lineTo(k + L, k); c.moveTo(w - k - L, k); c.lineTo(w - k, k); c.lineTo(w - k, k + L)
        c.moveTo(k, h - k - L); c.lineTo(k, h - k); c.lineTo(k + L, h - k); c.moveTo(w - k - L, h - k); c.lineTo(w - k, h - k); c.lineTo(w - k, h - k - L)
        c.stroke()
    }
}
