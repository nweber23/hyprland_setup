pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Which panel is open, on which screen, and where it should hang (x in screen coordinates).
Singleton {
    id: root
    property int initSteps: 0         // Tab presses made before the overview opened (the first one selects the previous window)
    property real earlyConfirm: 0     // ms timestamp of an Alt/Super release that came before the overview opened
    signal switchConfirm()            // Alt/Super released while the window overview is open
    signal switchStep(int dir)        // Alt+Tab pressed again while the window switcher is open
    property bool locked: false       // the lock screen is up (set by Lock.qml)
    property string launcherPrefill: "" // text the launcher opens with (quickshell ipc call shell launcher "...")
    property bool focusMode: false    // bar hidden, notifications silenced, a countdown running (Super+Z)
    property bool gameMode: false     // no blur, no animations (Super+Shift+G); mirrored from hyprland.lua through a file
    property bool builtinKbdOff: false  // the laptop keyboard is switched off (kbd-builtin), until Hyprland restarts
    property bool dockPinned: false   // dock held open (Super+D)
    property bool keepAwake: false    // no auto-lock, screen-off or suspend while on (the coffee button in the bar)
    property bool dnd: false          // do not disturb: notification popups hidden
    property var trayItem: null       // SystemTrayItem whose menu the "traymenu" panel shows
    property string annotatePath: ""  // the screenshot the editor opens (set by quickshell ipc call shell annotate)
    property string tab: ""           // sub-view of a panel, e.g. "wifi" / "bluetooth" for the network panel
    property string current: ""
    property string screenName: ""
    property real anchorX: 0
    property string lastClosed: ""
    property double lastClosedAt: 0

    function toggle(name, screen, x, tabArg) {
        // A click on the bar first dismisses the panel (focus grab), then reaches the chip:
        // without this guard the same click would reopen the panel it just closed.
        if (name === lastClosed && Date.now() - lastClosedAt < 250) return
        if (current === name && screenName === screen) {
            // same panel, other tab: switch instead of closing
            if (tabArg !== undefined && tabArg !== "" && tabArg !== tab) { tab = tabArg; return }
            close(); return
        }
        if (tabArg !== undefined && tabArg !== "") tab = tabArg
        current = name; screenName = screen; anchorX = x
    }
    function close() {
        if (current !== "") { lastClosed = current; lastClosedAt = Date.now() }
        current = ""
    }
    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell/gamemode.txt"
        watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: root.gameMode = text().trim() === "1"
    }

    // Focus mode on: silence notifications and start a 25 minute countdown; off: bring back what was there before.
    property bool dndBefore: false
    function setFocus(on) {
        if (on === focusMode) return
        focusMode = on
        if (on) { dndBefore = dnd; dnd = true; Tools.setTotal(1500); Tools.start() }
        else { dnd = dndBefore; if (Tools.running) Tools.reset() }
    }
    // the countdown ending (or being stopped) ends the focus mode too
    Connections { target: Tools; function onRunningChanged() { if (!Tools.running && root.focusMode) root.setFocus(false) } }
}
