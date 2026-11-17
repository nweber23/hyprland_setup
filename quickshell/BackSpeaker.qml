import QtQuick

// Volume: a loudspeaker cone pulsing to a slow beat, sound arcs leaving it.
BackBase {
    draw: (c, w, h, t, r) => {
        const cx = w * 0.5, cy = h * 0.88, R = w * 0.5
        const beat = Math.pow(Math.max(0, Math.sin(t * 2.6)), 6), k = 1 + 0.035 * beat
        for (let i = 0; i < 3; i++) {
            const p = (t / 4 + i / 3) % 1
            c.strokeStyle = r.p(0.22 * (1 - p)); c.lineWidth = 2
            c.beginPath(); c.arc(cx, cy, R * (1.05 + 0.9 * p), 3.6, 5.82); c.stroke()
        }
        c.fillStyle = r.p(0.1); c.beginPath(); r.circle(c, cx, cy, R * 1.04); c.fill()
        c.strokeStyle = r.p(0.28); c.lineWidth = 4; c.beginPath(); c.arc(cx, cy, R * 1.04, 0, 6.2832); c.stroke()
        c.fillStyle = r.p(0.12); c.beginPath(); r.circle(c, cx, cy, R * 0.78 * k); c.fill()
        c.strokeStyle = r.p(0.16); c.lineWidth = 2
        for (const f of [0.78, 0.6, 0.44]) { c.beginPath(); c.arc(cx, cy, R * f * k, 0, 6.2832); c.stroke() }
        c.fillStyle = r.t3(0.3); c.beginPath(); r.circle(c, cx, cy, R * 0.28 * k); c.fill()
        c.fillStyle = r.t3(0.2); c.beginPath(); r.circle(c, cx - R * 0.07, cy - R * 0.07, R * 0.1 * k); c.fill()
    }
}
