import QtQuick

// Network: nodes drifting about, joined by links with small packets travelling along them.
BackBase {
    draw: (c, w, h, t, r) => {
        const N = 20, pts = []
        for (let i = 0; i < N; i++) {
            const k = i * 12.9898
            pts.push({ x: (Math.sin(k) * 0.5 + 0.5) * w * 0.9 + w * 0.05 + 16 * Math.sin(t * 0.3 + i * 1.7),
                       y: (Math.sin(k * 2.3 + 1) * 0.5 + 0.5) * h * 0.92 + h * 0.04 + 16 * Math.cos(t * 0.27 + i * 2.1) })
        }
        const maxD = Math.max(w, h) * 0.42
        c.lineWidth = 1.5
        for (let i = 0; i < N; i++) for (let j = i + 1; j < N; j++) {
            const dx = pts[j].x - pts[i].x, dy = pts[j].y - pts[i].y, d = Math.sqrt(dx * dx + dy * dy)
            if (d > maxD) continue
            c.strokeStyle = r.p(0.3 * (1 - d / maxD)); c.beginPath(); c.moveTo(pts[i].x, pts[i].y); c.lineTo(pts[j].x, pts[j].y); c.stroke()
            if ((i + j) % 3 === 0) {
                const q = (t * 0.22 + (i * 7 + j * 3) * 0.13) % 1
                c.fillStyle = r.t3(0.7 * (1 - d / maxD)); c.beginPath(); r.circle(c, pts[i].x + dx * q, pts[i].y + dy * q, 2.4); c.fill()
            }
        }
        for (let i = 0; i < N; i++) {
            c.fillStyle = r.p(0.12); c.beginPath(); r.circle(c, pts[i].x, pts[i].y, 9); c.fill()
            c.fillStyle = r.p(0.5); c.beginPath(); r.circle(c, pts[i].x, pts[i].y, 3.5); c.fill()
        }
    }
}
