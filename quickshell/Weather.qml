pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Current weather from wttr.in (location is guessed from the IP address). Refreshed every 15 min.
Singleton {
    id: root
    property string text: ""

    Process {
        id: fetch
        command: ["curl", "-s", "--max-time", "10", "https://wttr.in/?format=%c%t"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                // wttr.in answers with an HTML/plain error page when it is unreachable; keep the old value then.
                if (t.length > 0 && t.length < 24 && !t.includes("<")) root.text = t
            }
        }
    }
    Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetch.running = true }
}
