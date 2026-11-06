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
    onLockedChanged: { Popups.locked = locked; if (!locked) { fp.abort(); fpRetry.stop() } }
    property bool checking: false
    property bool unlocking: false      // the unlock animation is playing
    property string error: ""
    // ---- fingerprint (fprintd): runs next to the password field while the screen is locked ----
    property bool fpAvailable: false     // a finger is enrolled
    property string fpMessage: ""        // what the sensor says: "Place your finger ...", "Failed to match ..."
    property bool fpError: false
    readonly property bool fpActive: fp.active
    signal failed()

    function lock() { if (!locked) { error = ""; unlocking = false; locked = true; fpCheck.running = true } }
    function succeed() { fp.abort(); unlocking = true; leave.start() }

    // Checks one password. Exposed as a function so the PAM stack can be tested without typing.
    function attempt(password) {
        if (checking || password === "") return
        checking = true; error = ""; pending = password
        fp.abort(); fpRetry.stop()   // one thing at a time: the password check takes over
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
            if (result === PamResult.Success) { root.succeed() }
            else { root.error = result === PamResult.Failed ? "Wrong password" : "Authentication error"; root.failed(); root.fpRetry.restart() }
        }
        onError: err => { root.checking = false; root.pending = ""; root.error = "Authentication error"; root.failed() }
    }

    // fingerprint: asked right when the lock comes up, and again after every miss
    Process { id: fpCheck; command: ["sh", "-c", 'fprintd-list "$USER" 2>/dev/null | grep -q "^ - #"']
              onExited: code => { root.fpAvailable = code === 0; if (root.fpAvailable && root.locked) fp.start() } }
    PamContext {
        id: fp
        configDirectory: Quickshell.shellDir + "/pam"
        config: "fingerprint.conf"
        user: Quickshell.env("USER")
        onMessageChanged: if (message !== "") {   // the reader's own sentences name the finger: show short fixed ones instead
            root.fpError = /fail|unable|error|not /i.test(message)
            root.fpMessage = root.fpError ? "Fingerprint not recognised" : "Touch the sensor"
        }
        onCompleted: result => {
            if (result === PamResult.Success) { root.succeed(); return }
            root.fpMessage = "Fingerprint not recognised"; root.fpError = true
            if (root.locked && !root.unlocking) root.fpRetry.restart()
        }
        onError: err => { if (root.locked && !root.unlocking) root.fpRetry.restart() }
    }
    property alias fpRetry: fpRetryTimer
    Timer { id: fpRetryTimer; interval: 2500; onTriggered: if (root.locked && !root.checking && !root.unlocking && root.fpAvailable && !fp.active) fp.start() }

    Timer { id: leave; interval: 380; onTriggered: { root.locked = false; root.unlocking = false } }   // lets the screen melt away first

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
