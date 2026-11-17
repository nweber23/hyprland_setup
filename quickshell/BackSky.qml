import QtQuick

// Weather and calendar: a landscape that shows the actual weather and time of day.
// Sun or moon over layered hills; clouds, rain, snow, fog or lightning depending on Weather.icon.
BackBase {
    function cloud(c, r, x, y, s, a, col) {
        c.fillStyle = col(a); c.beginPath()
        r.circle(c, x, y, s * 0.42); r.circle(c, x + s * 0.5, y - s * 0.22, s * 0.58); r.circle(c, x + s * 1.05, y - s * 0.02, s * 0.46)
        r.circle(c, x, y + s * 0.18, s * 0.27); r.circle(c, x + s * 1.3, y + s * 0.18, s * 0.27)
        c.moveTo(x, y - s * 0.09); c.lineTo(x, y + s * 0.45); c.lineTo(x + s * 1.3, y + s * 0.45); c.lineTo(x + s * 1.3, y - s * 0.09); c.closePath()
        c.fill()
    }
    function hills(c, w, h, base, amp, f, ph, col) {
        c.fillStyle = col; c.beginPath(); c.moveTo(0, h)
        for (let x = 0; x <= w; x += 6) c.lineTo(x, h * base - amp * (Math.sin(x * f + ph) * 0.6 + Math.sin(x * f * 2.3 + ph * 1.7) * 0.4))
        c.lineTo(w, h); c.closePath(); c.fill()
    }
    function rnd(i, k) { const x = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453; return x - Math.floor(x) }

    draw: (c, w, h, t, r) => {
        const ic = Weather.icon, hr = new Date().getHours(), night = hr < 6 || hr >= 20
        const clear = ic === "sunny", partly = ic === "partly_cloudy_day"
        const wet = ic === "rainy" || ic === "thunderstorm", snow = ic === "weather_snowy", fog = ic === "foggy", storm = ic === "thunderstorm"
        const dark = wet || snow || storm || ic === "cloud"

        // sky wash
        const sky = c.createLinearGradient(0, 0, 0, h * 0.7)
        sky.addColorStop(0, night ? r.s(0.2) : dark ? r.s(0.2) : r.t3(0.2)); sky.addColorStop(1, r.p(0))
        c.fillStyle = sky; c.fillRect(0, 0, w, h * 0.7)

        // sun or moon, hidden behind the weather when it is overcast
        const sx = w * 0.78, sy = h * 0.14, vis = (clear || partly) ? 1 : fog ? 0.35 : 0
        if (vis > 0) {
            if (night) {
                c.fillStyle = r.t3(0.5 * vis); c.beginPath(); r.circle(c, sx, sy, 30); c.fill()
                c.globalCompositeOperation = "destination-out"; c.fillStyle = "rgba(0,0,0,1)"; c.beginPath(); r.circle(c, sx + 15, sy - 8, 26); c.fill(); c.globalCompositeOperation = "source-over"
                for (let i = 0; i < 26; i++) { c.fillStyle = r.t3((0.2 + 0.45 * (0.5 + 0.5 * Math.sin(t * 1.2 + i * 1.7))) * vis); c.beginPath(); r.circle(c, rnd(i, 1) * w, rnd(i, 2) * h * 0.45, 1 + rnd(i, 3) * 1.3); c.fill() }
            } else {
                for (let i = 3; i >= 1; i--) { c.fillStyle = r.t3(0.07 * vis); c.beginPath(); r.circle(c, sx, sy, 30 + i * 24); c.fill() }
                c.fillStyle = r.t3(0.55 * vis); c.beginPath(); r.circle(c, sx, sy, 30); c.fill()
                c.strokeStyle = r.t3(0.4 * vis); c.lineWidth = 3; c.lineCap = "round"; c.beginPath()
                for (let i = 0; i < 14; i++) { const a = t * 0.07 + i * 0.4488, l = i % 2 ? 12 : 22; c.moveTo(sx + Math.cos(a) * 46, sy + Math.sin(a) * 46); c.lineTo(sx + Math.cos(a) * (46 + l), sy + Math.sin(a) * (46 + l)) }
                c.stroke()
            }
        }

        // clouds
        const n = clear ? 0 : partly ? 2 : 4
        for (let i = 0; i < n; i++) {
            const s = (partly ? 60 : 80) + 26 * rnd(i, 4), v = 4 + 7 * rnd(i, 5), y = h * (0.1 + 0.16 * i * (partly ? 1.2 : 1) + 0.03 * rnd(i, 6))
            const x = (((i + 0.4 * rnd(i, 7)) / n * (w + 400) + t * v) % (w + 400)) - 220
            cloud(c, r, x, y, s, dark ? 0.2 - 0.025 * i : 0.17, dark ? r.s : r.p)
        }

        // rain / snow / fog / lightning
        if (wet) {
            c.strokeStyle = r.p(0.4); c.lineWidth = 1.5; c.lineCap = "round"; c.beginPath()
            for (let i = 0; i < 70; i++) {
                const sp = 340 + 200 * rnd(i, 8), y = ((rnd(i, 9) * h + t * sp) % (h + 40)) - 20, x = ((rnd(i, 10) * (w + 80) - t * sp * 0.18) % (w + 80) + w + 80) % (w + 80) - 20
                c.moveTo(x, y); c.lineTo(x - 3.5, y + 13)
            }
            c.stroke()
        }
        if (snow) {
            for (let i = 0; i < 55; i++) {
                const sp = 28 + 30 * rnd(i, 8), y = ((rnd(i, 9) * h + t * sp) % (h + 20)) - 10, x = rnd(i, 10) * w + 14 * Math.sin(t * 0.7 + i)
                c.fillStyle = r.p(0.35 + 0.3 * rnd(i, 11)); c.beginPath(); r.circle(c, x, y, 1.6 + 1.8 * rnd(i, 12)); c.fill()
            }
        }
        if (fog) {
            for (let i = 0; i < 5; i++) {
                const y = h * (0.2 + 0.13 * i), x = ((t * (6 + 3 * i) + i * 140) % (w * 1.6)) - w * 0.5
                const g = c.createLinearGradient(x, 0, x + w * 0.9, 0); g.addColorStop(0, r.p(0)); g.addColorStop(0.5, r.p(0.16)); g.addColorStop(1, r.p(0))
                c.fillStyle = g; c.beginPath(); c.roundedRect(x, y, w * 0.9, 34, 17, 17); c.fill()
            }
        }
        if (storm) {
            const ph = t % 8, fl = ph < 0.12 ? 1 - ph / 0.12 : ph > 0.3 && ph < 0.4 ? 0.6 * (1 - (ph - 0.3) / 0.1) : 0
            if (fl > 0) {
                c.fillStyle = r.t3(0.14 * fl); c.fillRect(0, 0, w, h)
                c.fillStyle = r.t3(0.7 * fl); c.beginPath(); const bx = w * 0.3
                c.moveTo(bx + 10, h * 0.2); c.lineTo(bx - 14, h * 0.2 + 70); c.lineTo(bx + 2, h * 0.2 + 70); c.lineTo(bx - 16, h * 0.2 + 140); c.lineTo(bx + 24, h * 0.2 + 52); c.lineTo(bx + 6, h * 0.2 + 52); c.closePath(); c.fill()
            }
        }

        // landscape
        hills(c, w, h, 0.86, 26, 0.012, 0.8, night ? r.s(0.16) : r.s(0.14))
        hills(c, w, h, 0.93, 20, 0.017, 2.9, night ? r.p(0.2) : r.p(0.18))
    }
}
