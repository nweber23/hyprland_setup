import QtQuick

// System monitor: two live-looking load graphs scrolling by, filled underneath.
BackBase {
    draw: (c, w, h, t, r) => {
        c.strokeStyle = r.p(0.08); c.lineWidth = 1
        c.beginPath(); for (let i = 1; i < 6; i++) { const y = Math.round(h * i / 6) + 0.5; c.moveTo(0, y); c.lineTo(w, y) } c.stroke()
        const series = [ { col: 0, base: 0.74, amp: 0.34, v: 26, ph: 0 }, { col: 1, base: 0.9, amp: 0.2, v: 18, ph: 2.4 } ]
        for (const s of series) {
            const f = x => { const u = x + t * s.v; return 0.5 + 0.28 * Math.sin(u * 0.021 + s.ph) + 0.16 * Math.sin(u * 0.057 - s.ph) + 0.08 * Math.sin(u * 0.13 + 1.3) }
            const y = x => h * (s.base - s.amp * f(x))
            const gr = c.createLinearGradient(0, h * (s.base - s.amp), 0, h)
            gr.addColorStop(0, s.col ? r.t3(0.2) : r.p(0.26)); gr.addColorStop(1, s.col ? r.t3(0) : r.p(0))
            c.fillStyle = gr; c.beginPath(); c.moveTo(0, h)
            for (let x = 0; x <= w; x += 5) c.lineTo(x, y(x))
            c.lineTo(w, h); c.closePath(); c.fill()
            c.strokeStyle = s.col ? r.t3(0.5) : r.p(0.55); c.lineWidth = 2; c.beginPath()
            for (let x = 0; x <= w; x += 5) { if (x === 0) c.moveTo(x, y(x)); else c.lineTo(x, y(x)) }
            c.stroke()
        }
    }
}
