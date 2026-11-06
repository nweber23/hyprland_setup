pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// Live audio bars for the music widget: runs bin/spectrum (one process for all screens) only while a track plays.
Singleton {
    id: root
    property var levels: []             // 24 values, 0..100
    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)
    readonly property bool wanted: Settings.visualizer && Settings.widgets && playing && !Popups.gameMode && !Popups.locked
    onWantedChanged: if (!wanted) levels = []
    function init() {}
    Process {
        running: root.wanted
        command: ["spectrum"]
        stdout: SplitParser { onRead: line => root.levels = line.split(" ").map(Number) }
    }
}
