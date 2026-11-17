import QtQuick

// Screen time: a big clock face in the corner that shows the real time.
BackBase {
    draw: (c, w, h, t, r) => {
        const cx = w * 0.78, cy = h * 0.2, R = Math.min(w * 0.42, h * 0.2)
        const d = new Date(), sec = d.getSeconds() + d.getMilliseconds() / 1000, min = d.getMinutes() + sec / 60, hr = (d.getHours() % 12) + min / 60
        c.fillStyle = r.p(0.09); c.beginPath(); r.circle(c, cx, cy, R); c.fill()
        c.strokeStyle = r.p(0.28); c.lineWidth = 3; c.beginPath(); c.arc(cx, cy, R, 0, 6.2832); c.stroke()
        c.lineCap = "round"
        for (let i = 0; i < 60; i++) {
            const a = i * 0.10472 - 1.5708, big = i % 5 === 0, l = big ? 12 : 5
            c.strokeStyle = r.p(big ? 0.4 : 0.2); c.lineWidth = big ? 3 : 1.5
            c.beginPath(); c.moveTo(cx + Math.cos(a) * (R - 8), cy + Math.sin(a) * (R - 8)); c.lineTo(cx + Math.cos(a) * (R - 8 - l), cy + Math.sin(a) * (R - 8 - l)); c.stroke()
        }
        const hand = (ang, len, wd, col) => { c.strokeStyle = col; c.lineWidth = wd; c.beginPath(); c.moveTo(cx, cy); c.lineTo(cx + Math.cos(ang - 1.5708) * len, cy + Math.sin(ang - 1.5708) * len); c.stroke() }
        hand(hr * 0.5236, R * 0.5, 5, r.p(0.55)); hand(min * 0.10472, R * 0.75, 3.5, r.p(0.55)); hand(sec * 0.10472, R * 0.85, 2, r.t3(0.75))
        c.fillStyle = r.t3(0.8); c.beginPath(); r.circle(c, cx, cy, 5); c.fill()
    }
}
