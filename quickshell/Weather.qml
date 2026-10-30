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
    Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetch.running = true }
}
