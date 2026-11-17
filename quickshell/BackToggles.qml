import QtQuick

// Quick settings: a stack of switches that flip one after another.
BackBase {
    draw: (c, w, h, t, r) => {
        const pw = 112, ph = 52, rows = Math.max(3, Math.floor(h / 100))
        for (let i = 0; i < rows; i++) {
            const x = i % 2 ? w - pw - 18 : 18, y = 22 + i * (h - 44 - ph) / Math.max(1, rows - 1)
            const on = r.smooth(Math.sin(t * 0.45 + i * 1.9) * 2.5 + 0.5)
            c.fillStyle = r.p(0.08 + 0.14 * on); c.beginPath(); c.roundedRect(x, y, pw, ph, ph / 2, ph / 2); c.fill()
            c.strokeStyle = r.p(0.18); c.lineWidth = 2; c.beginPath(); c.roundedRect(x, y, pw, ph, ph / 2, ph / 2); c.stroke()
            c.fillStyle = r.t3(0.3 + 0.3 * on); c.beginPath(); r.circle(c, x + ph / 2 + on * (pw - ph), y + ph / 2, ph / 2 - 8); c.fill()
        }
    }
}
