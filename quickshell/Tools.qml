pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// State of the small tools, kept here so a timer keeps running while its panel is closed:
// countdown / pomodoro, stopwatch, notes and the calculator.
Singleton {
    id: root

    // ---- countdown and pomodoro ----
    property bool pomodoro: false       // 25 min focus, 5 min break, repeating
    property string phase: "focus"      // pomodoro phase
    property int cycles: 0              // finished focus phases
    property int total: 300             // seconds of the current countdown
    property real left: 300             // seconds left, live while running
    property bool running: false
    property real endAt: 0              // epoch ms when it ends

    function fmt(s) {
        s = Math.max(0, Math.ceil(s))
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), x = s % 60
        const two = n => (n < 10 ? "0" : "") + n
        return (h > 0 ? h + ":" + two(m) : two(m)) + ":" + two(x)
    }
    function setTotal(sec) { if (running) return; pomodoro = false; total = Math.max(5, sec); left = total }
    function togglePomodoro() {
        if (running) return
        pomodoro = !pomodoro; phase = "focus"; cycles = 0
        total = pomodoro ? 25 * 60 : 300; left = total
    }
    function start() {
        if (left <= 0) left = total
        endAt = Date.now() + left * 1000; running = true
    }
    function pause() { left = Math.max(0, (endAt - Date.now()) / 1000); running = false }
    function toggle() { running ? pause() : start() }
    function reset() { running = false; left = total }
    function finish() {
        running = false
        const wasFocus = phase === "focus"
        Quickshell.execDetached(["notify-send", "-a", "Timer", "-i", "alarm-symbolic",
                                 pomodoro ? (wasFocus ? "Focus phase done" : "Break over") : "Timer finished",
                                 pomodoro ? (wasFocus ? "Take a 5 minute break." : "Back to work.") : Tools.fmt(total) + " are up."])
        Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"])
        if (pomodoro) {
            if (wasFocus) cycles++
            phase = wasFocus ? "break" : "focus"
            total = phase === "focus" ? 25 * 60 : 5 * 60; left = total
            start()
        } else left = total
    }
    Timer {
        interval: 200; repeat: true; running: root.running
        onTriggered: { root.left = Math.max(0, (root.endAt - Date.now()) / 1000); if (root.left <= 0) root.finish() }
    }

    // ---- stopwatch ----
    property bool swRunning: false
    property real swBase: 0             // ms from earlier runs
    property real swStart: 0            // epoch ms of the current run
    property real swMs: 0
    property var laps: []               // ms, newest first
    function swToggle() {
        if (swRunning) { swBase += Date.now() - swStart; swMs = swBase; swRunning = false }
        else { swStart = Date.now(); swRunning = true }
    }
    function swLap() { if (swRunning || swMs > 0) laps = [swMs].concat(laps).slice(0, 20) }
    function swReset() { swRunning = false; swBase = 0; swMs = 0; laps = [] }
    function swFmt(ms) {
        const c = Math.floor(ms / 10) % 100, s = Math.floor(ms / 1000) % 60, m = Math.floor(ms / 60000)
        const two = n => (n < 10 ? "0" : "") + n
        return two(m) + ":" + two(s) + "." + two(c)
    }
    Timer { interval: 33; repeat: true; running: root.swRunning; onTriggered: root.swMs = root.swBase + Date.now() - root.swStart }

    // what the bar shows while something runs
    readonly property string barText: running ? fmt(left) : (swRunning ? swFmt(swMs).slice(0, 5) : "")

    // ---- notes ----
    property string notes: ""
    FileView {
        id: notesFile
        path: Quickshell.env("HOME") + "/.config/quickshell-local/notes.txt"
        printErrors: false
        onLoaded: root.notes = text()
    }
    function saveNotes(t) { notes = t; notesFile.setText(t) }

    // ---- calculator ----
    // Plain arithmetic only: the regex keeps everything but digits, operators and brackets out of eval.
    function calc(q) {
        if (!/^[0-9+\-*\/().,%^ ]+$/.test(q) || !/[+\-*\/%^]/.test(q) || !/[0-9]/.test(q)) return null
        try {
            const v = eval(q.replace(/,/g, ".").replace(/\^/g, "**"))
            return typeof v === "number" && isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : null
        } catch (e) { return null }
    }
}
