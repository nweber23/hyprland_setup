import QtQuick

// Vault: a padlock, its shackle lifting a little now and then, a glint crossing the body.
BackBase {
    draw: (c, w, h, t, r) => {
        const bw = Math.min(w * 0.52, 190), bh = bw * 0.82, cx = w / 2, bx = cx - bw / 2, by = h * 0.5
        const lift = 14 * r.smooth(Math.sin(t * 0.5) * 2 - 0.4)
        c.lineCap = "butt"; c.lineWidth = bw * 0.12; c.strokeStyle = r.p(0.2)
        const sr = bw * 0.3
        c.beginPath(); c.moveTo(cx - sr, by - lift); c.lineTo(cx - sr, by - sr * 0.9 - lift); c.arc(cx, by - sr * 0.9 - lift, sr, 3.1416, 0); c.lineTo(cx + sr, by - lift); c.stroke()
        c.fillStyle = r.p(0.16); c.beginPath(); c.roundedRect(bx, by, bw, bh, 20, 20); c.fill()
        c.strokeStyle = r.p(0.3); c.lineWidth = 2.5; c.beginPath(); c.roundedRect(bx, by, bw, bh, 20, 20); c.stroke()
        c.save(); c.beginPath(); c.roundedRect(bx, by, bw, bh, 20, 20); c.clip()
        const gx = bx + ((t * 0.35) % 1.8 - 0.4) * bw * 1.4
        const gr = c.createLinearGradient(gx - 40, by, gx + 40, by + bh * 0.4)
        gr.addColorStop(0, r.t3(0)); gr.addColorStop(0.5, r.t3(0.28)); gr.addColorStop(1, r.t3(0))
        c.fillStyle = gr; c.fillRect(bx, by, bw, bh); c.restore()
        c.fillStyle = r.t3(0.4); c.beginPath(); r.circle(c, cx, by + bh * 0.42, bw * 0.09); c.fill()
        c.beginPath(); c.moveTo(cx - bw * 0.04, by + bh * 0.42); c.lineTo(cx + bw * 0.04, by + bh * 0.42); c.lineTo(cx + bw * 0.06, by + bh * 0.68); c.lineTo(cx - bw * 0.06, by + bh * 0.68); c.closePath(); c.fill()
    }
}
