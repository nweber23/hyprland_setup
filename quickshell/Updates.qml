pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Pending apt updates, counted from apt's cached lists (no root needed; the system refreshes the lists itself).
Singleton {
    id: root
    property int count: 0
    property int security: 0   // of those, from the security pocket

    function check() { if (!proc.running) proc.running = true }
    // opens a terminal with the real commands, so sudo asks for the password there
    function install() {
        Quickshell.execDetached(["kitty", "-e", "bash", "-c", "sudo apt update && sudo apt upgrade; echo; read -rp 'Done. Press Enter to close. '"])
    }

    Process {
        id: proc
        command: ["sh", "-c", "apt list --upgradable 2>/dev/null | grep 'upgradable from'"]
        stdout: StdioCollector { onStreamFinished: {
            const lines = text.split("\n").filter(l => l !== "")
            root.count = lines.length
            root.security = lines.filter(l => l.includes("-security")).length
        } }
    }
    Timer { interval: 3600000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.check() }   // hourly
}
