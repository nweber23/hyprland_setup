import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Wallpaper layer with a cross-fade. The path comes from ~/.cache/quickshell/wallpaper.txt
// (written by bin/set-wallpaper), so changing the wallpaper never restarts the shell.
PanelWindow {
    id: root
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "qs-wallpaper"
    color: Theme.surface

    property string src: ""
    property bool front: true   // true: image A is visible, false: image B
    property bool started: false

    onSrcChanged: {
        if (src === "") return
        if (!started) { a.source = "file://" + src; started = true; return }
        (front ? b : a).source = "file://" + src   // load into the hidden image, swap when ready
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper.txt"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.src = text().trim()
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
}
