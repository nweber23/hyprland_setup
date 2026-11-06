import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

// Session lock screen (ext-session-lock): the compositor hides everything else while this is shown.
// Unlocking needs the account password, checked through PAM with pam/password.conf.
Scope {
    id: root
    property bool locked: false
    onLockedChanged: Popups.locked = locked
    property bool checking: false
    property bool unlocking: false      // the unlock animation is playing
    property string error: ""
    signal failed()

    function lock() { if (!locked) { error = ""; unlocking = false; locked = true } }

    // Checks one password. Exposed as a function so the PAM stack can be tested without typing.
    function attempt(password) {
        if (checking || password === "") return
        checking = true; error = ""; pending = password
        pam.start()
    }
    property string pending: ""

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/pam"
        config: "password.conf"
        user: Quickshell.env("USER")
        onResponseRequiredChanged: if (responseRequired) { respond(root.pending); root.pending = "" }
        onCompleted: result => {
            root.checking = false
            root.pending = ""
            if (result === PamResult.Success) { root.unlocking = true; leave.start() }
            else { root.error = result === PamResult.Failed ? "Wrong password" : "Authentication error"; root.failed() }
        }
        onError: err => { root.checking = false; root.pending = ""; root.error = "Authentication error"; root.failed() }
    }

    Timer { id: leave; interval: 480; onTriggered: { root.locked = false; root.unlocking = false } }   // lets the screen melt away first

    // Idle: lock after 5 minutes without input (apps that inhibit idle, e.g. video playback, are respected).
    // Enabled after unlocking with the real password was confirmed.
    property bool autoLock: true
    IdleMonitor { enabled: root.autoLock && Settings.lockMinutes > 0 && !Popups.keepAwake; timeout: Math.max(60, Settings.lockMinutes * 60); respectInhibitors: true; onIsIdleChanged: if (isIdle) root.lock() }

    // Screen off after 6 minutes without input while locked; any input switches it back on.
    IdleMonitor {
        enabled: Settings.screenOffMinutes > 0 && !Popups.keepAwake
        timeout: Math.max(60, Settings.screenOffMinutes * 60); respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle && root.locked) Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.dpms({ action = "off" })'])
            else if (!isIdle) Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.dpms({ action = "on" })'])
        }
    }

    property string wallpaper: ""
    FileView { path: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-still.txt"; watchChanges: true; onFileChanged: reload()   // a still image, also for video wallpapers
               onLoaded: root.wallpaper = text().trim() }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.surface
            LockView { anchors.fill: parent; lock: root }
        }
    }
}
