pragma Singleton
import Quickshell
import QtQuick

// Which panel is open, on which screen, and where it should hang (x in screen coordinates).
Singleton {
    property bool dnd: false          // do not disturb: notification popups hidden
    property string current: ""
    property string screenName: ""
    property real anchorX: 0
    property string lastClosed: ""
    property double lastClosedAt: 0

    function toggle(name, screen, x) {
        // A click on the bar first dismisses the panel (focus grab), then reaches the chip:
        // without this guard the same click would reopen the panel it just closed.
        if (name === lastClosed && Date.now() - lastClosedAt < 250) return
        if (current === name && screenName === screen) { close(); return }
        current = name; screenName = screen; anchorX = x
    }
    function close() {
        if (current !== "") { lastClosed = current; lastClosedAt = Date.now() }
        current = ""
    }
}
