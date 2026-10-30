pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Weather from wttr.in (location is guessed from the IP address), refreshed every 15 min.
Singleton {
    id: root
    property string temp: ""        // e.g. "12°"
    property string icon: "cloud"   // Material Symbols name
    property string desc: ""
    property string feelsLike: ""
    property var forecast: []       // [{ label, icon, max, min }] for today + 2 days
    property real tempNum: 0        // current values as numbers (gauges, counters)
    property real feelsNum: 0
    property real humidity: 0       // %
    property real wind: 0           // km/h
    property real rain: 0           // % chance in the current 3 h slot
    property var days: []           // [{ name, max, min, desc, hourly: [{ h, label, icon, temp }] }] today + 2 days

    property real lat: 0
    property real lon: 0

    // Open-Meteo reports WMO codes
    function wmoIcon(c) {
        if (c === 0) return "sunny"
        if (c === 1 || c === 2) return "partly_cloudy_day"
        if (c === 3) return "cloud"
        if (c === 45 || c === 48) return "foggy"
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "weather_snowy"
        if (c >= 95) return "thunderstorm"
        return "rainy"
    }
    function wmoDesc(c) {
        const t = { 0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Rime fog", 51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle",
                    56: "Freezing drizzle", 57: "Freezing drizzle", 61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain",
                    71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains", 80: "Rain showers", 81: "Rain showers", 82: "Heavy showers",
                    85: "Snow showers", 86: "Heavy snow showers", 95: "Thunderstorm", 96: "Thunderstorm, hail", 99: "Thunderstorm, hail" }
        return t[c] ?? "—"
    }

    function iconFor(code) {
        code = parseInt(code)
        if (code === 113) return "sunny"
        if (code === 116) return "partly_cloudy_day"
        if (code === 119 || code === 122) return "cloud"
        if ([143, 248, 260].includes(code)) return "foggy"
        if ([200, 386, 389, 392, 395].includes(code)) return "thunderstorm"
        if ([179, 182, 185, 227, 230, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(code)) return "weather_snowy"
        return "rainy"
    }

    Process {
        id: fetch
        command: ["curl", "-s", "--max-time", "10", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    const cur = j.current_condition[0]
                    root.lat = +j.nearest_area[0].latitude; root.lon = +j.nearest_area[0].longitude
                    if (!extended.running && root.lat !== 0) extended.running = true
                    root.temp = cur.temp_C + "°"
                    root.icon = root.iconFor(cur.weatherCode)
                    root.desc = cur.weatherDesc[0].value
                    root.feelsLike = cur.FeelsLikeC + "°"
                    root.tempNum = +cur.temp_C; root.feelsNum = +cur.FeelsLikeC
                    root.humidity = +cur.humidity; root.wind = +cur.windspeedKmph
                    root.rain = +j.weather[0].hourly[Math.min(7, Math.floor(new Date().getHours() / 3))].chanceofrain
                    root.days = j.weather.map((d, i) => ({
                        name: i === 0 ? "Today" : Qt.formatDate(new Date(d.date + "T12:00:00"), "dddd"),
                        max: +d.maxtempC, min: +d.mintempC,
                        desc: d.hourly[4].weatherDesc[0].value,
                        hourly: d.hourly.map(h => { const hh = Math.floor(+h.time / 100)
                            return { h: hh, label: String(hh).padStart(2, "0") + ":00", icon: root.iconFor(h.weatherCode), temp: h.tempC + "°" } })
                    }))
                    const days = ["Today", "Tomorrow"]
                    root.forecast = j.weather.map((d, i) => ({
                        label: i < 2 ? days[i] : Qt.formatDate(new Date(d.date), "ddd"),
                        icon: root.iconFor(d.hourly[4].weatherCode),   // midday slot
                        max: d.maxtempC + "°", min: d.mintempC + "°"
                    }))
                } catch (e) { /* offline or error page: keep the previous values */ }
            }
        }
    }
    // 14 days with hourly values (wttr.in only has 3)
    Process {
        id: extended
        command: ["curl", "-s", "--max-time", "12", "https://api.open-meteo.com/v1/forecast?latitude=" + root.lat + "&longitude=" + root.lon
                  + "&hourly=temperature_2m,weather_code,relative_humidity_2m&daily=weather_code,temperature_2m_max,temperature_2m_min,wind_speed_10m_max,precipitation_probability_max,apparent_temperature_max"
                  + "&timezone=auto&forecast_days=14&wind_speed_unit=kmh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text), d = j.daily, h = j.hourly
                    const out = d.time.map((date, i) => {
                        const slots = []
                        for (let k = 0; k < 8; k++) {
                            const idx = i * 24 + k * 3
                            slots.push({ h: k * 3, label: String(k * 3).padStart(2, "0") + ":00", icon: root.wmoIcon(h.weather_code[idx]), temp: Math.round(h.temperature_2m[idx]) + "°" })
                        }
                        let hum = 0; for (let k = 0; k < 24; k++) hum += h.relative_humidity_2m[i * 24 + k]
                        return {
                            name: i === 0 ? "Today" : Qt.formatDate(new Date(date + "T12:00:00"), "dddd"),
                            date: date, max: Math.round(d.temperature_2m_max[i]), min: Math.round(d.temperature_2m_min[i]),
                            desc: root.wmoDesc(d.weather_code[i]), wind: d.wind_speed_10m_max[i], humidity: hum / 24,
                            rain: d.precipitation_probability_max[i] ?? 0, feels: d.apparent_temperature_max[i], hourly: slots
                        }
                    })
                    if (out.length > 0) root.days = out
                } catch (e) { /* keep the 3 days from wttr.in */ }
            }
        }
    }
    Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetch.running = true }
}
