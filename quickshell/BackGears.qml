import QtQuick

// Settings: two meshing gears turning slowly.
BackBase {
    function gear(c, cx, cy, R, n, ang, th) {
        const u = 6.2832 / n
        c.beginPath()
        for (let k = 0; k < n; k++) {
            const a = ang + k * u
            const pts = [[0, R], [0.14, R + th], [0.46, R + th], [0.6, R]]
            for (let i = 0; i < 4; i++) { const x = cx + Math.cos(a + pts[i][0] * u) * pts[i][1], y = cy + Math.sin(a + pts[i][0] * u) * pts[i][1]; if (k === 0 && i === 0) c.moveTo(x, y); else c.lineTo(x, y) }
        }
        c.closePath()
    }
    draw: (c, w, h, t, r) => {
        const R1 = Math.min(w * 0.3, 120), n1 = 12, R2 = R1 * 0.66, n2 = 8, th = R1 * 0.17
        const x1 = w * 0.74, y1 = h * 0.17, dir = 2.2, d = R1 + R2 + th * 0.2
        const x2 = x1 - Math.cos(dir) * -d, y2 = y1 + Math.sin(dir) * d
        const a1 = t * 0.16, a2 = -a1 * n1 / n2 + 3.1416 / n2 + dir * (1 + n1 / n2)
        const body = (x, y, R, n, a, col) => {
            gear(c, x, y, R, n, a, th)
            c.fillStyle = col(0.14); c.fill(); c.strokeStyle = col(0.34); c.lineWidth = 2.5; c.stroke()
            c.strokeStyle = col(0.25); c.lineWidth = 2; c.beginPath(); c.arc(x, y, R * 0.4, 0, 6.2832); c.stroke()
            c.fillStyle = col(0.3); c.beginPath(); r.circle(c, x, y, R * 0.12); c.fill()
        }
        body(x1, y1, R1, n1, a1, r.p)
        body(x2, y2, R2, n2, a2, r.t3)
    }
}
