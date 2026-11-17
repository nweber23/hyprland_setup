import QtQuick

// Shortcuts: keycaps in staggered rows, one key pressed at a time.
BackBase {
    draw: (c, w, h, t, r) => {
        const K = 44, g = 8, rows = Math.floor((h - g) / (K + g)), cols = Math.floor(w / (K + g)) + 1
        const n = rows * cols, cur = Math.floor(t * 1.8 * 1.0) % n, cur2 = (cur * 7 + 3) % n, env = Math.sin(((t * 1.8) % 1) * 3.1416)
        for (let j = 0; j < rows; j++) for (let i = 0; i < cols; i++) {
            const idx = j * cols + i, x = g + i * (K + g) - (j % 3) * 14, y = g + j * (K + g)
            const pr = idx === cur2 ? env : 0
            c.fillStyle = r.p(0.05); c.beginPath(); c.roundedRect(x, y + 5, K, K, 9, 9); c.fill()
            c.fillStyle = r.p(0.09 + 0.2 * pr); c.beginPath(); c.roundedRect(x, y + 5 * pr, K, K - 4, 9, 9); c.fill()
            c.strokeStyle = r.p(0.14 + 0.25 * pr); c.lineWidth = 1.5; c.beginPath(); c.roundedRect(x, y + 5 * pr, K, K - 4, 9, 9); c.stroke()
        }
    }
}
