pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick

// Battery care: low-charge warnings, power-saver profile at 20 % and below, suspend after idle on battery,
// and the battery's health. Started from shell.qml via init().
Singleton {
    id: root
    readonly property var dev: UPower.displayDevice
    // UPower reports 0..100 on D-Bus; guard in case a build exposes 0..1.
    readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 100
    readonly property bool onBattery: UPower.onBattery
    property int health: 0        // % of the design capacity the battery still holds, 0 = unknown
    property int cycles: 0
    property int warned: 0        // 1 low (20), 2 very low (10), 3 critical (5); reset when charging
    property string before: ""    // power profile to restore after charging, "" = we changed nothing

    function init() {}            // referencing the singleton is what starts it

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Battery", "-i", "battery-caution", title, body])
    }
    function check() {
        if (!onBattery) {
            warned = 0
            if (before !== "") { Quickshell.execDetached(["powerprofilesctl", "set", before]); before = "" }
            return
        }
        const p = Math.round(pct)
        if (p <= 5 && warned < 3) { warned = 3; notify("Battery critical: " + p + " %", "Plug in the charger now.") }
        else if (p <= 10 && warned < 2) { warned = 2; notify("Battery very low: " + p + " %", "Power saver is on. Plug in soon.") }
        else if (p <= 20 && warned < 1) { warned = 1; notify("Battery low: " + p + " %", Settings.autoSaver ? "Switching to power saver." : "Plug in soon.") }
        if (p <= 20 && Settings.autoSaver && before === "") getProfile.running = true
    }
    onPctChanged: check()
    onOnBatteryChanged: check()

    // remember the current profile once, then switch; restored by check() when the charger is back
    Process {
        id: getProfile
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: {
            const cur = text.trim()
            if (cur !== "" && cur !== "power-saver") { root.before = cur; Quickshell.execDetached(["powerprofilesctl", "set", "power-saver"]) }
        } }
    }

    IdleMonitor {
        enabled: root.onBattery && Settings.suspendMinutes > 0
        timeout: Math.max(60, Settings.suspendMinutes * 60); respectInhibitors: true
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
    }

    Process {
        running: true
        command: ["sh", "-c", "for b in /sys/class/power_supply/BAT*; do [ -r $b/energy_full_design ] && echo $(cat $b/energy_full) $(cat $b/energy_full_design) $(cat $b/cycle_count 2>/dev/null || echo 0) && break; done"]
        stdout: StdioCollector { onStreamFinished: {
            const p = text.trim().split(" ").map(Number)
            if (p.length === 3 && p[1] > 0) { root.health = Math.round(100 * p[0] / p[1]); root.cycles = p[2] }
        } }
    }
}
