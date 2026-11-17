import QtQuick

// Music: a record turning in the lower corner, grooves and light reflections.
BackBase {
    draw: (c, w, h, t, r) => {
        const cx = w * 0.72, cy = h * 0.9, R = w * 0.7, a = t * 0.5
        c.fillStyle = r.p(0.11); c.beginPath(); r.circle(c, cx, cy, R); c.fill()
        c.strokeStyle = r.p(0.08); c.lineWidth = 1
        for (let g = R * 0.4; g < R * 0.97; g += 7) { c.beginPath(); c.arc(cx, cy, g, 0, 6.2832); c.stroke() }
        c.strokeStyle = r.p(0.22); c.lineWidth = 2; c.beginPath(); c.arc(cx, cy, R, 0, 6.2832); c.stroke()
        for (let k = 0; k < 2; k++) {
            c.fillStyle = r.p(0.07); c.beginPath(); c.moveTo(cx, cy); c.arc(cx, cy, R * 0.97, a + k * 3.1416, a + k * 3.1416 + 0.55); c.closePath(); c.fill()
        }
        c.fillStyle = r.t3(0.3); c.beginPath(); r.circle(c, cx, cy, R * 0.3); c.fill()
        c.fillStyle = r.t3(0.5); c.beginPath(); r.circle(c, cx + Math.cos(a) * R * 0.21, cy + Math.sin(a) * R * 0.21, 5); c.fill()
        c.fillStyle = "rgba(0,0,0,1)"; c.globalCompositeOperation = "destination-out"; c.beginPath(); r.circle(c, cx, cy, 6); c.fill(); c.globalCompositeOperation = "source-over"
        // tonearm
        const px = w - 26, py = 26
        c.strokeStyle = r.s(0.28); c.lineWidth = 5; c.lineCap = "round"
        c.beginPath(); c.moveTo(px, py); c.lineTo(px - 10, py + h * 0.3); c.lineTo(cx + R * 0.52, cy - R * 0.62); c.stroke()
        c.fillStyle = r.s(0.3); c.beginPath(); r.circle(c, px, py, 12); c.fill()
    }
}
