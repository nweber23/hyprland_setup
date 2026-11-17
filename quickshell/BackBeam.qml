import QtQuick

// Projector: a projector at the top casting a cone of light with dust drifting through it.
BackBase {
    draw: (c, w, h, t, r) => {
        const lx = w / 2, ly = 66, spread = w * 0.62
        const gr = c.createLinearGradient(0, ly, 0, h)
        gr.addColorStop(0, r.t3(0.3)); gr.addColorStop(1, r.t3(0.03))
        c.fillStyle = gr; c.beginPath(); c.moveTo(lx - 14, ly); c.lineTo(lx + 14, ly); c.lineTo(lx + spread, h); c.lineTo(lx - spread, h); c.closePath(); c.fill()
        c.fillStyle = r.p(0.22); c.beginPath(); c.roundedRect(lx - 70, 14, 140, 48, 12, 12); c.fill()
        c.strokeStyle = r.p(0.35); c.lineWidth = 2; c.beginPath(); c.roundedRect(lx - 70, 14, 140, 48, 12, 12); c.stroke()
        c.fillStyle = r.t3(0.5); c.beginPath(); r.circle(c, lx, 62, 16); c.fill()
        c.fillStyle = r.p(0.3); for (let i = 0; i < 3; i++) { c.beginPath(); r.circle(c, lx - 50 + i * 12, 30, 2.5); c.fill() }
        for (let i = 0; i < 36; i++) {
            const k = i * 12.9898, f = (Math.sin(k) * 0.5 + 0.5), y = ly + ((f * h + t * (8 + 10 * f)) % (h - ly)), half = 14 + (spread - 14) * (y - ly) / (h - ly)
            const x = lx + (Math.sin(k * 3.1 + t * 0.2 * (0.5 + f)) * 0.9) * half
            c.fillStyle = r.t3(0.2 + 0.45 * f); c.beginPath(); r.circle(c, x, y, 1.2 + 1.4 * f); c.fill()
        }
    }
}
