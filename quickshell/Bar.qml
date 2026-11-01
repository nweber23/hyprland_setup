import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Floating top bar made of separate pills.
PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    margins { top: 6; left: 8; right: 8 }
    implicitHeight: 34
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"

    readonly property font textFont: Qt.font({ family: Theme.mono, pixelSize: 12, bold: true })

    // ---- state ----------------------------------------------------------------
    readonly property var player: {
        const ps = Mpris.players.values
        for (let i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i]
        return ps.length > 0 ? ps[0] : null
    }

    readonly property var sink: Audio.sink       // the real output, also while the equalizer is on
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    readonly property var battery: UPower.displayDevice
    // UPower reports 0..100 on D-Bus; guard in case a build exposes 0..1.
    readonly property real batteryPct: battery ? (battery.percentage > 1 ? battery.percentage : battery.percentage * 100) : 0
    readonly property bool charging: battery && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged)

    SystemClock { id: clock; precision: SystemClock.Seconds }

    function volumeIcon() {
        if (muted || volume <= 0) return "volume_off"
        return volume < 0.34 ? "volume_mute" : volume < 0.67 ? "volume_down" : "volume_up"
    }
    function batteryIcon() {
        if (charging) return "battery_charging_full"
        const p = batteryPct
        return p > 90 ? "battery_full" : p > 70 ? "battery_5_bar" : p > 50 ? "battery_4_bar"
             : p > 35 ? "battery_3_bar" : p > 20 ? "battery_2_bar" : p > 8 ? "battery_1_bar" : "battery_alert"
    }
    function openPanel(name, item, tab) {
        const p = item.mapToItem(null, item.width / 2, 0)
        Popups.toggle(name, bar.screen.name, p.x + bar.margins.left, tab)
    }
    // Each monitor has its own workspaces (the laptop panel 1-10, the next monitor 11-20, ...), see hyprland.lua.
    readonly property var hyprMonitor: Hyprland.monitors.values.find(m => m.name === screen.name) ?? null
    readonly property int wsOffset: {
        if (screen.name.startsWith("eDP")) return 0
        const names = Hyprland.monitors.values.map(m => m.name).filter(n => !n.startsWith("eDP")).sort()
        const i = names.indexOf(screen.name)
        return i < 0 ? 0 : 10 * (i + 1)
    }
    function focusWorkspace(n) { Quickshell.execDetached(["hyprctl", "eval", "qsGotoWorkspace(" + Math.round(n) + ")"]) }   // switches every monitor

    function fmt(us) { us = Math.max(0, Math.floor(us)); return String(Math.floor(us / 60)).padStart(2, "0") + ":" + String(us % 60).padStart(2, "0") }
    // MPRIS does not push the position: refresh it while something plays
    Timer { running: bar.player !== null && bar.player.isPlaying; interval: 1000; repeat: true; onTriggered: bar.player.positionChanged() }

    // ---- left ------------------------------------------------------------------
    RowLayout {
        anchors.left: parent.left
        height: parent.height
        spacing: 6

        BarGroup {
            id: searchBtn
            implicitWidth: 34; padding: 0
            BarChip { Layout.fillWidth: true; Icon { name: "search"; size: 18 } onClicked: bar.openPanel("launcher", searchBtn) }
        }
        BarGroup {
            id: bellBtn
            implicitWidth: 34; padding: 0
            BarChip { Layout.fillWidth: true; active: Popups.current === "notifications"
                // left click: notification center, right click: do not disturb; a dot marks unread ones
                Icon { name: Popups.dnd ? "notifications_off" : "notifications"; size: 18; color: Popups.dnd ? Theme.accent : Theme.on_surface
                       Rectangle { visible: NotifHistory.unread > 0 && !Popups.dnd; x: parent.width - 7; y: 1; width: 8; height: 8; radius: 4; color: Theme.accent2 } }
                onClicked: m => { if (m.button === Qt.RightButton) Popups.dnd = !Popups.dnd; else bar.openPanel("notifications", bellBtn) } }
        }

        BarGroup {
            spacing: 2
            Repeater {
                model: 8
                delegate: Rectangle {
                    required property int index
                    readonly property int number: index + 1                  // the key: Super + number
                    readonly property int wsId: number + bar.wsOffset        // this monitor's workspace id
                    readonly property bool active: bar.hyprMonitor && bar.hyprMonitor.activeWorkspace && bar.hyprMonitor.activeWorkspace.id === wsId
                    readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)
                    Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 7
                    color: active ? Theme.accent : occupied ? Theme.cardHigh : "transparent"
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: parent.number; font: bar.textFont
                           color: parent.active ? Theme.panelBg : parent.occupied ? Theme.on_surface : Theme.on_surface_variant }
                    MouseArea { anchors.fill: parent; onClicked: bar.focusWorkspace(parent.number) }
                }
            }
        }

        BarGroup {
            id: mediaGroup
            visible: bar.player !== null
            padding: 5; spacing: 8
            onClicked: bar.openPanel("music", mediaGroup)
            ClippingRectangle {
                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 6; color: Theme.card
                Image { anchors.fill: parent; source: bar.player ? bar.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
            }
            ColumnLayout {
                Layout.maximumWidth: 190; spacing: 0
                Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight
                       text: bar.player ? bar.player.trackTitle : ""; color: Theme.on_surface; font: bar.textFont }
                Text { textFormat: Text.PlainText; Layout.fillWidth: true
                       text: bar.player ? bar.fmt(bar.player.position) + " / " + bar.fmt(bar.player.length) : ""
                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 9 }
            }
            Item { Layout.preferredWidth: 4 }
            Icon { name: "skip_previous"; size: 18; fill: 1; MouseArea { anchors.fill: parent; onClicked: bar.player.previous() } }
            Icon { name: bar.player && bar.player.isPlaying ? "pause" : "play_arrow"; size: 20; fill: 1
                   MouseArea { anchors.fill: parent; onClicked: bar.player.togglePlaying() } }
            Icon { name: "skip_next"; size: 18; fill: 1; MouseArea { anchors.fill: parent; onClicked: bar.player.next() } }
            Item { Layout.preferredWidth: 2 }
        }
    }

    // ---- centre: clock + weather --------------------------------------------------
    RowLayout {
        anchors.centerIn: parent
        height: parent.height
        spacing: 6
        BarGroup {
            id: clockGroup
            padding: 12
            implicitHeight: 34
            onClicked: bar.openPanel("calendar", clockGroup)
            ColumnLayout {
                spacing: 0
                Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: Qt.formatTime(clock.date, "HH:mm:ss")
                       color: Theme.accent; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
                Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: Qt.formatDate(clock.date, "dddd, d MMMM")
                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 8 }
            }
        }
        BarGroup {
            visible: Weather.temp !== ""
            padding: 10; spacing: 6
            onClicked: bar.openPanel("calendar", clockGroup)
            Icon { name: Weather.icon; size: 18; fill: 1; color: Theme.on_surface }
            Text { textFormat: Text.PlainText; text: Weather.temp; color: Theme.on_surface; font: bar.textFont }
        }
    }

    // ---- right: tray + status ------------------------------------------------------
    RowLayout {
        anchors.right: parent.right
        height: parent.height
        spacing: 6

        BarGroup {
            padding: 6; spacing: 8
            Repeater {
                model: SystemTray.items
                delegate: IconImage {
                    id: trayIcon
                    required property var modelData
                    implicitSize: 16
                    source: modelData.icon
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: m => {
                            // right click (or left click on menu-only items) opens the menu; left click activates
                            // Applets like nm-applet have a menu but ignore Activate, so their left click opens the menu too
                            const menuFirst = trayIcon.modelData.onlyMenu || trayIcon.modelData.id === "nm-applet" || trayIcon.modelData.id.endsWith("-applet")
                            if (m.button === Qt.RightButton || (m.button === Qt.LeftButton && menuFirst)) {
                                if (trayIcon.modelData.hasMenu) { Popups.trayItem = trayIcon.modelData; bar.openPanel("traymenu", trayIcon) }
                                else trayIcon.modelData.secondaryActivate()
                            } else if (m.button === Qt.MiddleButton) trayIcon.modelData.secondaryActivate()
                            else trayIcon.modelData.activate()
                        }
                    }
                }
            }
            Icon { id: monIcon; name: "monitor_heart"; size: 17; MouseArea { anchors.fill: parent; onClicked: bar.openPanel("sysmon", monIcon) } }
            Icon { id: setIcon; name: "settings"; size: 17; MouseArea { anchors.fill: parent; onClicked: bar.openPanel("settings", setIcon) } }
            // a recording must never run unnoticed: red, pulsing, click to stop
            Rectangle {
                visible: Recorder.recording
                Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: 11; color: Qt.alpha(Theme.error, 0.25)
                Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: Theme.error
                            SequentialAnimation on opacity { running: Recorder.recording; loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 700; easing.type: Easing.InOutSine } NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine } } }
                MouseArea { anchors.fill: parent; onClicked: Recorder.stop() }
            }
            Icon {   // keep awake: no auto-lock, screen-off or suspend while it is on
                id: awakeIcon; name: "local_cafe"; size: 17
                color: Popups.keepAwake ? Theme.accent : Theme.on_surface
                fill: Popups.keepAwake ? 1 : 0
                MouseArea { anchors.fill: parent; onClicked: Popups.keepAwake = !Popups.keepAwake }
            }
            Item {   // tools: timer, stopwatch, notes, calculator; shows the running time
                implicitWidth: toolsRow.implicitWidth; implicitHeight: 22
                RowLayout { id: toolsRow; anchors.centerIn: parent; spacing: 4
                    Icon { id: toolsIcon; name: "timer"; size: 17; color: Tools.barText !== "" ? Theme.accent : Theme.on_surface }
                    Text { visible: Tools.barText !== ""; textFormat: Text.PlainText; text: Tools.barText; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 11; font.bold: true } }
                MouseArea { anchors.fill: parent; onClicked: bar.openPanel("tools", toolsIcon) }
            }
            Icon { id: capIcon; name: "photo_camera"; size: 17; MouseArea { anchors.fill: parent; onClicked: bar.openPanel("capture", capIcon) } }
            Icon { id: dispIcon; name: "desktop_windows"; size: 17; MouseArea { anchors.fill: parent; onClicked: bar.openPanel("display", dispIcon) } }
            Icon { id: timeIcon; name: "hourglass_top"; size: 17; MouseArea { anchors.fill: parent; onClicked: bar.openPanel("screentime", timeIcon) } }
        }

        BarGroup {
            spacing: 4
            BarChip {
                // click or scroll: next layout (Super+Space and Alt+Shift also switch)
                onClicked: Keyboard.cycle()
                onScrolled: Keyboard.cycle()
                Icon { name: "keyboard"; size: 16 }
                Text { textFormat: Text.PlainText; text: Keyboard.layout; color: Theme.on_surface; font: bar.textFont }
            }
            BarChip {
                id: wifiChip
                fillColor: Net.wifiNetwork ? Theme.accent : "transparent"
                onClicked: bar.openPanel("network", wifiChip, "wifi")
                Icon { name: Net.wifiNetwork ? "wifi" : "wifi_off"; size: 16; fill: 1; color: Net.wifiNetwork ? Theme.panelBg : Theme.outline }
                Text { textFormat: Text.PlainText; visible: Net.wifiNetwork !== null; text: Net.wifiNetwork ? Net.wifiNetwork.name : ""
                       color: Theme.panelBg; font: bar.textFont; Layout.maximumWidth: 110; elide: Text.ElideRight }
            }
            BarChip {
                id: btChip
                fillColor: Net.btDevice ? Theme.accent : "transparent"
                onClicked: bar.openPanel("network", btChip, "bluetooth")
                Icon { name: Net.btDevice ? "bluetooth_connected" : "bluetooth"; size: 16; fill: 1; color: Net.btDevice ? Theme.panelBg : Theme.outline }
                Text { textFormat: Text.PlainText; visible: Net.btDevice !== null; color: Theme.panelBg; font: bar.textFont; Layout.maximumWidth: 110; elide: Text.ElideRight
                       text: Net.btDevice ? Net.btDevice.name : "" }
            }
            BarChip {
                id: volChip
                fillColor: bar.muted ? "transparent" : Theme.accent2
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) { if (bar.sink && bar.sink.audio) bar.sink.audio.muted = !bar.sink.audio.muted }
                    else bar.openPanel("volume", volChip)
                }
                onScrolled: wheel => {
                    if (!bar.sink || !bar.sink.audio) return
                    const v = bar.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)
                    bar.sink.audio.volume = Math.max(0, Math.min(1, v))
                }
                Icon { name: bar.volumeIcon(); size: 16; fill: 1; color: bar.muted ? Theme.outline : Theme.panelBg }
                Text { textFormat: Text.PlainText; text: Math.round(bar.volume * 100); color: bar.muted ? Theme.outline : Theme.panelBg; font: bar.textFont }
            }
            BarChip {
                id: batChip
                visible: bar.battery !== null && bar.battery.isLaptopBattery
                // while charging the chip breathes softly in the accent colour
                property real glow: 0.12
                fillColor: bar.charging ? Qt.alpha(Theme.accent, glow) : "transparent"
                SequentialAnimation on glow { running: bar.charging; loops: Animation.Infinite
                    NumberAnimation { to: 0.34; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.12; duration: 1400; easing.type: Easing.InOutSine } }
                active: Popups.current === "power" && Popups.screenName === bar.screen.name
                onClicked: bar.openPanel("power", batChip)
                Icon { name: bar.batteryIcon(); size: 16; fill: 1; color: bar.charging ? Theme.accent : bar.batteryPct <= 15 ? Theme.error : Theme.on_surface }
                Text { textFormat: Text.PlainText; text: Math.round(bar.batteryPct); color: Theme.on_surface; font: bar.textFont }
            }
        }
    }
}
