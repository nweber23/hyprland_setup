pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Upcoming events from an iCalendar source. Put either of these in ~/.config/quickshell-local/
// (outside the git repo, a calendar URL is a secret):
//   calendar-url.txt  one line, e.g. Google Calendar "secret address in iCal format"
//   calendar.ics      an exported file
// Limitation: recurring events (RRULE) are not expanded.
Singleton {
    id: root
    property var upcoming: []        // [{ title, start (Date), allDay }]
    property bool configured: true

    function parseDate(v) {
        // 20261030T140000Z | 20261030T140000 | 20261030
        const m = v.match(/^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z?))?/)
        if (!m) return null
        if (!m[4]) return { d: new Date(+m[1], +m[2] - 1, +m[3]), allDay: true }
        const args = [+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]]
        return { d: m[7] ? new Date(Date.UTC(...args)) : new Date(...args), allDay: false }
    }

    function parse(ics) {
        const lines = ics.replace(/\r/g, "").replace(/\n[ \t]/g, "").split("\n")
        const out = []; let ev = null
        for (const l of lines) {
            if (l === "BEGIN:VEVENT") ev = {}
            else if (l === "END:VEVENT") { if (ev && ev.title && ev.start) out.push(ev); ev = null }
            else if (ev) {
                const i = l.indexOf(":"); if (i < 0) continue
                const key = l.slice(0, i).split(";")[0], val = l.slice(i + 1)
                if (key === "SUMMARY") ev.title = val.replace(/\\,/g, ",").replace(/\\n/g, " ")
                else if (key === "DTSTART") { const p = parseDate(val); if (p) { ev.start = p.d; ev.allDay = p.allDay } }
            }
        }
        const now = Date.now() - 3600000, limit = Date.now() + 30 * 86400000
        return out.filter(e => e.start.getTime() >= now && e.start.getTime() <= limit)
                  .sort((a, b) => a.start - b.start).slice(0, 5)
    }

    Process {
        id: load
        command: ["sh", "-c", 'd="$HOME/.config/quickshell-local"; if [ -f "$d/calendar-url.txt" ]; then curl -s --max-time 15 "$(cat "$d/calendar-url.txt")"; elif [ -f "$d/calendar.ics" ]; then cat "$d/calendar.ics"; else echo NOSOURCE; fi']
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "NOSOURCE") { root.configured = false; root.upcoming = []; return }
                root.configured = true
                try { root.upcoming = root.parse(text) } catch (e) { console.warn("Events: parse failed", e) }
            }
        }
    }
    Timer { interval: 1800000; running: true; repeat: true; triggeredOnStart: true; onTriggered: load.running = true }
}
