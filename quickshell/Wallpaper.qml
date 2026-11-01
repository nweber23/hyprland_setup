import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
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
    property bool front: true   // true: image A is visible, false: image B
    property bool started: false

    onImgSrcChanged: {
        if (imgSrc === "") return
        if (!started) { a.source = "file://" + imgSrc; started = true; return }
        (front ? b : a).source = "file://" + imgSrc   // load into the hidden image, swap when ready
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
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }
    }

    Layer {
        id: a
        opacity: root.front ? 1 : 0
        onStatusChanged: if (status === Image.Ready && root.started && !root.front) root.front = true
    }
    Layer {
        id: b
        opacity: root.front ? 0 : 1
        onStatusChanged: if (status === Image.Ready && root.front && source != "") root.front = false
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
