pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Live system numbers for the system monitor: CPU, memory, temperature, disk, network and the busiest processes.
// Sampled once a second, but only while a panel asks for it (active).
Singleton {
    id: root
    property bool active: false
    property real cpu: 0          // %
    property real mem: 0          // %
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real temp: 0         // CPU, degrees C
    property real gpuTemp: 0
    property real ssdTemp: 0
    property real disk: 0         // % of /
    property real down: 0         // bytes per second
    property real up: 0
    property var procs: []        // [{ name, cpu }]
    property real uptime: 0       // seconds
    property var cpuHist: []      // last 60 samples
    property var netHist: []
    property int tick: 0          // bumps on every sample (charts scroll)

    property var lastCpu: null
    property var lastNet: null
    property double lastT: 0

    Process {
        id: sample
        command: ["sh", "-c", 'head -1 /proc/stat; echo "--"; awk "/MemTotal|MemAvailable/{print \\$2}" /proc/meminfo; echo "--"; '
                 + 'for d in /sys/class/hwmon/hwmon*; do n=$(cat "$d/name" 2>/dev/null); case "$n" in k10temp|amdgpu|nvme) echo "$n $(cat "$d/temp1_input" 2>/dev/null)";; esac; done; echo "--"; df -B1 --output=used,size / | tail -1; echo "--"; '
                 + 'awk "/:/ && \\$1 !~ /^lo:/ {rx+=\\$2; tx+=\\$10} END {print rx+0, tx+0}" /proc/net/dev; echo "--"; '
                 + 'ps -eo comm=,pcpu= --sort=-pcpu | head -5; echo "--"; cut -d" " -f1 /proc/uptime']
        stdout: StdioCollector {
            onStreamFinished: {
                const sec = text.split("--\n")
                if (sec.length < 7) return
                const now = Date.now()
                // cpu: share of non-idle time since the last sample
                const c = sec[0].trim().split(/\s+/).slice(1).map(Number)
                const idle = c[3] + c[4], total = c.reduce((a, b) => a + b, 0)
                if (root.lastCpu) { const dt = total - root.lastCpu.total; root.cpu = dt > 0 ? 100 * (1 - (idle - root.lastCpu.idle) / dt) : root.cpu }
                root.lastCpu = { idle: idle, total: total }
                const m = sec[1].trim().split("\n").map(Number)         // MemTotal, MemAvailable (kB)
                root.memTotalGb = m[0] / 1048576; root.memUsedGb = (m[0] - m[1]) / 1048576; root.mem = 100 * (m[0] - m[1]) / m[0]
                const heat = {}
                for (const l of sec[2].trim().split("\n")) { const q = l.trim().split(" "); heat[q[0]] = (+q[1] || 0) / 1000 }
                root.temp = heat.k10temp ?? 0; root.gpuTemp = heat.amdgpu ?? 0; root.ssdTemp = heat.nvme ?? 0
                const d = sec[3].trim().split(/\s+/).map(Number); root.disk = d[1] > 0 ? 100 * d[0] / d[1] : 0
                const n = sec[4].trim().split(/\s+/).map(Number)
                if (root.lastNet && now > root.lastT) { const s = (now - root.lastT) / 1000; root.down = Math.max(0, (n[0] - root.lastNet[0]) / s); root.up = Math.max(0, (n[1] - root.lastNet[1]) / s) }
                root.lastNet = n; root.lastT = now
                root.procs = sec[5].trim().split("\n").map(l => { const p = l.trim().split(/\s+/); return { name: p.slice(0, -1).join(" "), cpu: +p[p.length - 1] } })
                root.uptime = +sec[6]
                const ch = root.cpuHist.slice(-59); ch.push(root.cpu); root.cpuHist = ch
                const nh = root.netHist.slice(-59); nh.push(root.down + root.up); root.netHist = nh
                root.tick++
            }
        }
    }
    Timer { interval: 1000; repeat: true; running: root.active; triggeredOnStart: true; onTriggered: if (!sample.running) sample.running = true }

    // Overheating: checked every 20 s even when no panel is open; one warning, re-armed once it has cooled down.
    property bool hot: false
    function init() {}   // referencing the singleton starts the watcher
    Process {
        id: heatCheck
        command: ["sh", "-c", 'for d in /sys/class/hwmon/hwmon*; do [ "$(cat "$d/name" 2>/dev/null)" = k10temp ] && cat "$d/temp1_input"; done']
        stdout: StdioCollector { onStreamFinished: {
            const t = (+text.trim() || 0) / 1000
            if (t >= 90 && !root.hot) {
                root.hot = true
                Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "System", "-i", "dialog-warning", "The CPU is very hot: " + Math.round(t) + " \u00b0C",
                                         "Close heavy programs or check that the vents are free."])
            } else if (t < 82) root.hot = false
        } }
    }
    Timer { interval: 20000; repeat: true; running: true; triggeredOnStart: true; onTriggered: if (!heatCheck.running) heatCheck.running = true }
}
