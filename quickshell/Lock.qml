import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// Session lock screen (ext-session-lock): the compositor hides everything else while this is shown.
// Unlocking needs the account password, checked through PAM with pam/password.conf.
Scope {
    id: root
    property bool locked: false
    property bool checking: false
    property string error: ""
    signal failed()

    function lock() { if (!locked) { error = ""; locked = true } }

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
            if (result === PamResult.Success) { root.locked = false }
            else { root.error = result === PamResult.Failed ? "Wrong password" : "Authentication error"; root.failed() }
        }
        onError: err => { root.checking = false; root.pending = ""; root.error = "Authentication error"; root.failed() }
    }

    // Idle: lock after 5 minutes without input (apps that inhibit idle, e.g. video playback, are respected).
    // Enabled after unlocking with the real password was confirmed.
    property bool autoLock: true
    IdleMonitor { enabled: root.autoLock && Settings.lockMinutes > 0; timeout: Math.max(60, Settings.lockMinutes * 60); respectInhibitors: true; onIsIdleChanged: if (isIdle) root.lock() }

    // Screen off after 6 minutes without input while locked; any input switches it back on.
    IdleMonitor {
        enabled: Settings.screenOffMinutes > 0
        timeout: Math.max(60, Settings.screenOffMinutes * 60); respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle && root.locked) Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.dpms({ action = "off" })'])
            else if (!isIdle) Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.dpms({ action = "on" })'])
        }
    }

    property string wallpaper: ""
    FileView { path: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper.txt"; watchChanges: true; onFileChanged: reload()
               onLoaded: root.wallpaper = text().trim() }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.surface

            Image {
                anchors.fill: parent
                source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(surface.width, surface.height)
                asynchronous: true
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; brightness: -0.25 }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText
                       text: Qt.formatTime(clock.date, "HH:mm"); color: Theme.on_surface
                       font.family: "JetBrains Mono"; font.pixelSize: 96; font.bold: true }
                Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText
                       text: Qt.formatDate(clock.date, "dddd, d MMMM"); color: Theme.on_surface_variant
                       font.family: "JetBrains Mono"; font.pixelSize: 18 }

                Rectangle {
                    id: field
                    Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 36
                    implicitWidth: 340; implicitHeight: 52; radius: 26
                    color: Qt.alpha(Theme.surface_container, 0.85)
                    border.width: 1; border.color: root.error !== "" ? Theme.error : Qt.alpha(Theme.outline_variant, 0.8)
                    Behavior on border.color { ColorAnimation { duration: 160 } }
                    SequentialAnimation on x {   // shake on a wrong password
                        id: shake; running: false
                        NumberAnimation { to: -12; duration: 50 } NumberAnimation { to: 12; duration: 70 }
                        NumberAnimation { to: -8; duration: 60 } NumberAnimation { to: 0; duration: 50 }
                    }
                    Connections { target: root; function onFailed() { pw.text = ""; shake.restart() } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                        spacing: 12
                        Icon { name: root.checking ? "hourglass_top" : "lock"; size: 22; color: Theme.on_surface_variant }
                        TextInput {
                            id: pw
                            Layout.fillWidth: true
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            color: Theme.on_surface; selectionColor: Theme.primary
                            font.family: "JetBrains Mono"; font.pixelSize: 16
                            focus: true
                            enabled: !root.checking
                            onAccepted: { root.attempt(pw.text); }
                            Component.onCompleted: forceActiveFocus()
                            Text { visible: pw.text === ""; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText
                                   text: "Password"; color: Theme.outline; font: pw.font }
                        }
                    }
                }
                Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText
                       text: root.error; opacity: root.error !== "" ? 1 : 0; color: Theme.error
                       font.family: "JetBrains Mono"; font.pixelSize: 13 }
            }
            SystemClock { id: clock; precision: SystemClock.Minutes }
        }
    }
}
