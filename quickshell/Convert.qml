pragma Singleton
import Quickshell
import QtQuick

// Unit and currency conversion for the launcher: "5 km in mi", "70 f to c", "20 usd in eur".
// Units are converted here; currencies are only recognised (the launcher asks a rate service for those).
Singleton {
    // factor to the base unit of each group (temperature is special-cased)
    readonly property var groups: ({
        length: { mm: 0.001, cm: 0.01, m: 1, km: 1000, inch: 0.0254, zoll: 0.0254, ft: 0.3048, yd: 0.9144, mi: 1609.344 },
        mass: { mg: 0.000001, g: 0.001, kg: 1, t: 1000, oz: 0.028349523, lb: 0.45359237, lbs: 0.45359237 },
        volume: { ml: 0.001, cl: 0.01, l: 1, gal: 3.785411784, floz: 0.0295735 },
        speed: { ms: 1, kmh: 0.27777778, mph: 0.44704, kn: 0.51444444 },
        data: { b: 1, kb: 1000, mb: 1e6, gb: 1e9, tb: 1e12, kib: 1024, mib: 1048576, gib: 1073741824 },
        time: { s: 1, sec: 1, min: 60, h: 3600, d: 86400, w: 604800 },
        temp: { c: 1, f: 1, k: 1 }
    })
    function groupOf(u) { for (const g in groups) if (groups[g][u] !== undefined) return g; return "" }
    function fmt(v) { return String(Number(v.toPrecision(7))) }

    // -> { kind: "unit", text, value } | { kind: "currency", amount, from, to } | null
    function parse(q) {
        const m = /^(-?\d+(?:[.,]\d+)?)\s*([a-zäöü]+)\s+(?:to|in|nach|->|=)\s+([a-zäöü]+)$/i.exec(q.trim())
        if (!m) return null
        const n = parseFloat(m[1].replace(",", ".")), a = m[2].toLowerCase(), b = m[3].toLowerCase()
        const g = groupOf(a)
        if (g !== "" && g === groupOf(b)) {
            let v
            if (g === "temp") {
                const c = a === "c" ? n : a === "f" ? (n - 32) * 5 / 9 : n - 273.15
                v = b === "c" ? c : b === "f" ? c * 9 / 5 + 32 : c + 273.15
            } else v = n * groups[g][a] / groups[g][b]
            return { kind: "unit", value: fmt(v), text: fmt(n) + " " + a + " = " + fmt(v) + " " + b }
        }
        if (/^[a-z]{3}$/.test(a) && /^[a-z]{3}$/.test(b) && g === "" && groupOf(b) === "")
            return { kind: "currency", amount: n, from: a.toUpperCase(), to: b.toUpperCase() }
        return null
    }
}
