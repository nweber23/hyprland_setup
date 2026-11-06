import Quickshell
import Quickshell.Wayland
import QtQuick

// Click effect: a ring where the pointer clicked. The window only exists while a ring is running and lets all input through.
PanelWindow {
    id: win
    visible: r0.busy || r1.busy || r2.busy
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}   // empty: every click goes to the window below
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-ripple"

    property int next: 0
    Connections {
        target: Popups
        function onRippleAt(gx, gy) {
            const x = gx - win.screen.x, y = gy - win.screen.y
            if (x < 0 || y < 0 || x > win.width || y > win.height) return   // another screen's click
            const ring = [r0, r1, r2][win.next]
            win.next = (win.next + 1) % 3
            ring.fire(x, y)
        }
    }
    RippleRing { id: r0 }
    RippleRing { id: r1 }
    RippleRing { id: r2 }
}
