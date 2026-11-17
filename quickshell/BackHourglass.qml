import QtQuick

// Tools (countdown, stopwatch, notes, calculator): an hourglass; the sand runs through, then it flips.
BackBase {
    draw: (c, w, h, t, r) => {
        const H = Math.min(h * 0.28, w * 0.42), W = H * 0.72, nk = H * 0.06
        const T = 18, p = (t % T) / T, s = Math.min(1, p / 0.92), f = r.smooth((p - 0.92) / 0.08)
        c.save(); c.translate(w / 2, h * 0.52); c.rotate(3.1416 * f)
        const bulbs = () => { c.beginPath()
            c.moveTo(-W, -H); c.lineTo(W, -H); c.lineTo(nk, 0); c.lineTo(W, H); c.lineTo(-W, H); c.lineTo(-nk, 0); c.closePath() }
        bulbs(); c.fillStyle = r.p(0.09); c.fill()
        c.save(); bulbs(); c.clip()
        c.fillStyle = r.t3(0.38)
        c.fillRect(-W, -H * (1 - s), W * 2, H * (1 - s))              // sand left in the top bulb (settled toward the neck)
        c.beginPath(); c.moveTo(-W, H); c.lineTo(W, H); c.lineTo(0, H - s * H * 0.95); c.closePath(); c.fill()   // the pile below
        if (p < 0.92) { c.strokeStyle = r.t3(0.55); c.lineWidth = 2; c.beginPath(); c.moveTo(0, 0); c.lineTo(0, H - s * H * 0.95); c.stroke() }
        c.restore()
        bulbs(); c.strokeStyle = r.p(0.34); c.lineWidth = 3; c.lineJoin = "round"; c.stroke()
        c.fillStyle = r.p(0.3)
        c.beginPath(); c.roundedRect(-W - 14, -H - 16, W * 2 + 28, 16, 6, 6); c.fill()
        c.beginPath(); c.roundedRect(-W - 14, H, W * 2 + 28, 16, 6, 6); c.fill()
        c.restore()
    }
}
