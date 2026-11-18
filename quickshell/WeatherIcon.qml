import QtQuick

// Solid weather glyph drawn by hand (the font's weather icons are part outline). `name` is Weather.icon.
Canvas {
    property string name: "cloud"
    property real size: 20
    property color color: Theme.on_surface
    width: size; height: size
    onColorChanged: requestPaint()
    onNameChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"), s = width, n = name
        c.reset(); c.fillStyle = color; c.strokeStyle = color; c.lineCap = "round"; c.lineWidth = s * 0.08
        const dot = (x, y, r) => { c.beginPath(); c.arc(x * s, y * s, r * s, 0, 6.2832); c.fill() }
        const cloud = (x, y, k) => {   // blob centred on x,y, width ~ k*s
            const ci = (dx, dy, r) => { c.beginPath(); c.arc(x + dx * k * s, y + dy * k * s, r * k * s, 0, 6.2832); c.fill() }
            ci(-0.2, 0.05, 0.2); ci(0.02, -0.08, 0.26); ci(0.25, 0.06, 0.2)
            c.fillRect(x - 0.2 * k * s, y + 0.05 * k * s, 0.45 * k * s, 0.2 * k * s)
        }
        const sun = (x, y, r, rays) => {
            dot(x, y, r)
            if (!rays) return
            for (let i = 0; i < 8; i++) { const a = i * 0.7854; c.beginPath(); c.moveTo((x + Math.cos(a) * (r + 0.07)) * s, (y + Math.sin(a) * (r + 0.07)) * s); c.lineTo((x + Math.cos(a) * (r + 0.15)) * s, (y + Math.sin(a) * (r + 0.15)) * s); c.stroke() }
        }
        if (n === "sunny") sun(0.5, 0.5, 0.2, true)
        else if (n === "partly_cloudy_day") { sun(0.36, 0.36, 0.15, true); cloud(0.55 * s, 0.64 * s, 1.0) }
        else if (n === "foggy") { cloud(0.5 * s, 0.36 * s, 0.9); for (const y of [0.66, 0.84]) { c.beginPath(); c.moveTo(0.16 * s, y * s); c.lineTo(0.84 * s, y * s); c.stroke() } }
        else if (n === "weather_snowy") { cloud(0.5 * s, 0.36 * s, 0.9); for (const x of [0.28, 0.5, 0.72]) dot(x, 0.76, 0.06); dot(0.39, 0.9, 0.05); dot(0.61, 0.9, 0.05) }
        else if (n === "thunderstorm") {
            cloud(0.5 * s, 0.34 * s, 0.9)
            c.beginPath(); c.moveTo(0.54 * s, 0.56 * s); c.lineTo(0.38 * s, 0.76 * s); c.lineTo(0.5 * s, 0.76 * s); c.lineTo(0.42 * s, 0.94 * s); c.lineTo(0.66 * s, 0.7 * s); c.lineTo(0.54 * s, 0.7 * s); c.closePath(); c.fill()
        } else if (n === "rainy") {
            cloud(0.5 * s, 0.34 * s, 0.9)
            for (const x of [0.3, 0.5, 0.7]) { c.beginPath(); c.moveTo((x + 0.04) * s, 0.64 * s); c.lineTo((x - 0.04) * s, 0.84 * s); c.stroke() }
        } else cloud(0.5 * s, 0.5 * s, 1.0)
    }
}
