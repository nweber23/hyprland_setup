import QtQuick

// Fallback: a dot grid with one soft diagonal highlight passing over it.
BackBase {
    draw: (c, w, h, t, r) => {
        const S = 20, pos = (t * 36) % (w + h * 0.6 + 360) - 180
        for (let y = S / 2; y < h; y += S)
            for (let x = S / 2; x < w; x += S) {
                const d = x + y * 0.6 - pos, g = Math.exp(-d * d / 9800)
                c.fillStyle = r.p(0.1 + 0.22 * g)
                c.beginPath(); c.arc(x, y, 0.9 + 0.5 * g, 0, 6.2832); c.fill()
            }
    }
}
