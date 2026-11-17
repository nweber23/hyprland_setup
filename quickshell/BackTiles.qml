import QtQuick

// Dock apps: a grid of app tiles, one lighting up at a time.
BackBase {
    draw: (c, w, h, t, r) => {
        const cols = 4, gap = 14, sz = (w - gap * (cols + 1)) / cols, rows = Math.floor((h - gap) / (sz + gap)), n = cols * rows
        const cur = Math.floor(t / 1.3) % n, env = Math.sin(((t / 1.3) % 1) * 3.1416)
        for (let i = 0; i < n; i++) {
            const x = gap + (i % cols) * (sz + gap), y = gap + Math.floor(i / cols) * (sz + gap), lit = i === cur ? env : 0
            c.fillStyle = r.p(0.07 + 0.15 * lit); c.beginPath(); c.roundedRect(x, y, sz, sz, sz * 0.26, sz * 0.26); c.fill()
            c.strokeStyle = r.p(0.12 + 0.2 * lit); c.lineWidth = 1.5; c.beginPath(); c.roundedRect(x, y, sz, sz, sz * 0.26, sz * 0.26); c.stroke()
            c.fillStyle = r.t3(0.1 + 0.4 * lit); c.beginPath(); r.circle(c, x + sz / 2, y + sz / 2, sz * 0.16); c.fill()
        }
    }
}
