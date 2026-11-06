import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects
import QtMultimedia

// Wallpaper layer with a cross-fade. The path comes from ~/.cache/quickshell/wallpaper.txt
// (written by bin/set-wallpaper), so changing the wallpaper never restarts the shell.
// A video wallpaper plays on top of its first frame (the still), and pauses when it cannot be seen or costs battery.
PanelWindow {
    id: root
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "qs-wallpaper"
    color: Theme.surface

    property string src: ""            // image or video, as chosen
    property string still: ""          // an image: the wallpaper itself, or one frame of the video
    readonly property bool isVideo: /\.(mp4|mkv|webm|mov)$/i.test(src)
    readonly property string imgSrc: still !== "" ? still : (isVideo ? "" : src)
    property bool started: false
    property bool revealing: false     // a new picture is growing in as a circle
    property bool pendingReveal: false
    property real cx: width / 2        // where the circle starts: the pointer, kept inside this screen
    property real cy: height / 2
    property real radius: 0
    readonly property real maxRadius: Math.hypot(width, height)

    onImgSrcChanged: {
        if (imgSrc === "") return
        if (!started) { base.source = "file://" + imgSrc; started = true; return }
        pendingReveal = true
        fresh.source = "file://" + imgSrc   // loaded on top, revealed once decoded
        if (fresh.status === Image.Ready) beginReveal()
    }
    function beginReveal() { if (pendingReveal && !cursor.running) { cursor.running = true; fallback.restart() } }
    function startGrow() {
        if (!pendingReveal) return
        pendingReveal = false; fallback.stop()
        revealing = true; radius = 0; grow.restart()
    }
    function finish() { revealing = false; radius = 0 }
    // pointer position, so the circle grows from where you clicked
    Process {
        id: cursor
        command: ["hyprctl", "-j", "cursorpos"]
        stdout: StdioCollector { onStreamFinished: {
            try { const p = JSON.parse(text)
                  root.cx = Math.max(0, Math.min(root.width, p.x - (root.screen ? root.screen.x : 0)))
                  root.cy = Math.max(0, Math.min(root.height, p.y - (root.screen ? root.screen.y : 0))) } catch (e) {}
            root.startGrow() } }
    }
    Timer { id: fallback; interval: 400; onTriggered: root.startGrow() }
    NumberAnimation {
        id: grow; target: root; property: "radius"; from: 0; to: root.maxRadius
        duration: 1000; easing.type: Easing.OutCubic
        onFinished: { if (base.source == fresh.source) root.finish(); else base.source = fresh.source }   // the hidden base takes the picture over
    }

    // ---- video ----
    // Playing only when it can be seen and is worth it: not locked, no fullscreen window, and (by default) not on battery.
    readonly property bool shouldPlay: isVideo && !Popups.locked && !Popups.gameMode
        && !(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.hasFullscreen)
        && (Settings.liveOnBattery || !UPower.onBattery)
    onShouldPlayChanged: if (shouldPlay) player.play(); else player.pause()
    MediaPlayer {
        id: player
        source: root.isVideo ? "file://" + root.src : ""
        loops: MediaPlayer.Infinite                    // no audioOutput: always silent
        videoOutput: vout
        onSourceChanged: vout.framed = false
        onMediaStatusChanged: if (mediaStatus === MediaPlayer.LoadedMedia && root.shouldPlay) play()
        onPlaybackStateChanged: if (playbackState === MediaPlayer.PlayingState) vout.framed = true
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper.txt"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.src = text().trim()
    }
    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-still.txt"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.still = text().trim()
    }

    component Layer: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(root.width, root.height)   // decode at screen size, not at 4K
    }

    Layer {
        id: base
        onStatusChanged: if (status === Image.Ready && root.revealing && source == fresh.source) root.finish()
    }
    // the new picture, shown only through a growing circle
    Item {
        id: circle
        anchors.fill: parent
        visible: false
        layer.enabled: root.revealing
        Rectangle { x: root.cx - root.radius; y: root.cy - root.radius; width: root.radius * 2; height: width; radius: width / 2 }
    }
    Layer {
        id: fresh
        visible: root.revealing
        layer.enabled: root.revealing
        layer.effect: MultiEffect { maskEnabled: true; maskSource: circle; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }
        onStatusChanged: if (status === Image.Ready) root.beginReveal()
    }
    // the video fades in over the still once its first frame is there
    VideoOutput {
        id: vout
        property bool framed: false
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        opacity: root.isVideo && framed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    }
}
