pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Whether a screen recording is running (wf-recorder), checked every two seconds.
Singleton {
    id: root
    property bool recording: false
    function stop() { Quickshell.execDetached(["record", "full"]) }   // the script toggles: a second call stops it
    Process {
        id: check
        command: ["sh", "-c", "pgrep -x wf-recorder >/dev/null && echo yes; true"]
        stdout: StdioCollector { onStreamFinished: root.recording = text.includes("yes") }
    }
    Timer { interval: 2000; repeat: true; running: true; triggeredOnStart: true; onTriggered: check.running = true }
}
