import QtQuick

// Weather and calendar: sun (or moon and stars at night) with clouds drifting past.
BackBase {
    draw: (c, w, h, t, r) => {
        const hr = new Date().getHours(), night = hr < 6 || hr >= 20
        const sx = w * 0.8, sy = h * 0.13
        if (!night) {
            c.fillStyle = r.t3(0.1); c.beginPath(); r.circle(c, sx, sy, 66); c.fill()
            c.fillStyle = r.t3(0.3); c.beginPath(); r.circle(c, sx, sy, 32); c.fill()
            c.strokeStyle = r.t3(0.3); c.lineWidth = 3; c.lineCap = "round"
            c.beginPath()
            for (let i = 0; i < 12; i++) { const a = t * 0.08 + i * 0.5236, co = Math.cos(a), si = Math.sin(a), l = i % 2 ? 10 : 18
                c.moveTo(sx + co * 46, sy + si * 46); c.lineTo(sx + co * (46 + l), sy + si * (46 + l)) }
            c.stroke()
        } else {
            c.fillStyle = r.t3(0.32); c.beginPath(); r.circle(c, sx, sy, 34); c.fill()
            c.globalCompositeOperation = "destination-out"
            c.fillStyle = "rgba(0,0,0,1)"; c.beginPath(); r.circle(c, sx + 17, sy - 9, 29); c.fill()
            c.globalCompositeOperation = "source-over"
            for (let i = 0; i < 22; i++) {
                const k = i * 12.9898, x = (Math.sin(k) * 0.5 + 0.5) * w, y = (Math.sin(k * 2.7) * 0.5 + 0.5) * h * 0.4
                c.fillStyle = r.t3(0.15 + 0.35 * (0.5 + 0.5 * Math.sin(t * 1.3 + i)))
                c.beginPath(); r.circle(c, x, y, 1.4); c.fill()
            }
        }
        const clouds = [ { y: 0.2, s: 60, v: 9, a: 0.16, o: 0.0 }, { y: 0.31, s: 90, v: 5, a: 0.11, o: 0.45 }, { y: 0.09, s: 44, v: 13, a: 0.13, o: 0.75 } ]
        for (const cl of clouds) {
            const x = ((cl.o * (w + 400) + t * cl.v) % (w + 400)) - 200, y = h * cl.y, s = cl.s
            c.fillStyle = r.p(cl.a); c.beginPath()
            r.circle(c, x, y, s * 0.42); r.circle(c, x + s * 0.5, y - s * 0.22, s * 0.58); r.circle(c, x + s * 1.05, y - s * 0.02, s * 0.46)
            r.circle(c, x, y + s * 0.18, s * 0.27); r.circle(c, x + s * 1.3, y + s * 0.18, s * 0.27)
            c.moveTo(x, y - s * 0.09); c.lineTo(x, y + s * 0.45); c.lineTo(x + s * 1.3, y + s * 0.45); c.lineTo(x + s * 1.3, y - s * 0.09); c.closePath()
            c.fill()
        }
    }
}
