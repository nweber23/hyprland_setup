import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

// Settings for everything: a sidebar of pages, each page a few rows. Changes apply at once.
Panel {
    id: root
    name: "settings"
    backdrop: "Orbits"
    panelWidth: 920
    centered: true
    pad: 18
    fixedH: 640

    property int page: 0
    readonly property var pages: [
        { name: "Appearance", icon: "palette" }, { name: "Desktop", icon: "dashboard" }, { name: "Display", icon: "desktop_windows" }, { name: "Sound", icon: "volume_up" },
        { name: "Network", icon: "wifi" }, { name: "Keyboard", icon: "keyboard" }, { name: "Mouse & touchpad", icon: "mouse" }, { name: "Night light", icon: "nightlight" },
        { name: "Power & lock", icon: "lock_clock" }, { name: "Notifications", icon: "notifications" }, { name: "Calendar", icon: "calendar_month" },
        { name: "Shortcuts", icon: "keyboard_command_key" }, { name: "About", icon: "info" }
    ]
    function open(name) { Popups.toggle(name, Popups.screenName, Popups.anchorX) }

    // ---------- state read from the system when the panel opens ----------
    property string wallpaper: ""
    property var layouts: ["us", "de"]
    property string kbSwitch: "grp:alt_shift_toggle"
    property bool nlOn: false
    property real nlTemp: 3800
    property string hyprVersion: ""
    property string calUrl: ""
    FileView { path: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper.txt"; watchChanges: true; onFileChanged: reload(); onLoaded: root.wallpaper = text().trim() }
    Process {
        id: kbRead
        command: ["hyprctl", "-j", "getoption", "input:kb_layout"]
        stdout: StdioCollector { onStreamFinished: { try { const l = JSON.parse(text).str.split(",").filter(x => x); if (l.length) root.layouts = l } catch (e) {} } }
    }
    Process {
        id: kbOpt
        command: ["hyprctl", "-j", "getoption", "input:kb_options"]
        stdout: StdioCollector { onStreamFinished: { try { root.kbSwitch = JSON.parse(text).str.includes("alt_shift") ? "grp:alt_shift_toggle" : "" } catch (e) {} } }
    }
    Process {
        id: nlRead
        command: ["nightlight", "status"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(" "); root.nlOn = p[0] === "on"; if (p[1]) root.nlTemp = +p[1] } }
    }
    Process {
        id: ver
        command: ["sh", "-c", "hyprctl version | head -1; quickshell --version 2>&1 | head -1"]
        stdout: StdioCollector { onStreamFinished: root.hyprVersion = text.trim() }
    }
    onShownChanged: if (shown) {
        kbRead.running = true; kbOpt.running = true; nlRead.running = true; ver.running = true
        const i = root.pages.findIndex(pg => pg.name === Popups.tab)   // opened on a given page: quickshell ipc call shell settings "<page>"
        if (i >= 0) page = i
        Popups.tab = ""
    }

    Timer { id: nlSet; interval: 350; onTriggered: Quickshell.execDetached(["nightlight", "set", String(Math.round(root.nlTemp))]) }

    function applyTheme(mode) {
        Settings.set("themeMode", mode)
        if (wallpaper !== "") Quickshell.execDetached(["env", "THEME_MODE=" + mode, "set-wallpaper", wallpaper])
    }
    // the layouts come from a fixed list, so nothing user-typed ends up in the Lua text
    // Everything is built from fixed lists and numbers, so nothing user-typed ends up in the Lua text.
    function inputLua() {
        const num = v => String(Number(v))
        return 'hl.config({ input = { kb_layout = "' + layouts.join(",") + '", kb_options = "' + kbSwitch + '", '
             + 'sensitivity = ' + num(Settings.pointerSpeed) + ', accel_profile = "' + Settings.accelProfile + '", '
             + 'repeat_rate = ' + Math.round(Settings.repeatRate) + ', repeat_delay = ' + Math.round(Settings.repeatDelay) + ', '
             + 'touchpad = { natural_scroll = ' + (Settings.naturalScroll ? "true" : "false") + ', tap_to_click = ' + (Settings.tapToClick ? "true" : "false")
             + ', disable_while_typing = ' + (Settings.disableTyping ? "true" : "false") + ', scroll_factor = ' + num(Settings.scrollSpeed) + ' } } })\n'
    }
    function applyInput() {
        const lua = inputLua()
        kbFile.setText("-- Written by the shell's settings; loaded last by hyprland.lua.\n" + lua)
        Quickshell.execDetached(["hyprctl", "eval", lua])
        refreshKb.restart()
    }
    function applyKeyboard() { applyInput() }
    function setInput(key, value) { Settings.set(key, value); inputApply.restart() }
    Timer { id: inputApply; interval: 300; onTriggered: root.applyInput() }
    FileView { id: kbFile; path: Quickshell.env("HOME") + "/.config/hypr/input-local.lua"; printErrors: false }
    Timer { id: refreshKb; interval: 600; onTriggered: Keyboard.refresh() }
    function saveCalendar(url) {
        Quickshell.execDetached(["sh", "-c", 'umask 077; mkdir -p "$HOME/.config/quickshell-local"; printf %s "$1" > "$HOME/.config/quickshell-local/calendar-url.txt"', "sh", url])
        calTimer.restart()
    }
    Timer { id: calTimer; interval: 700; onTriggered: Events.reload() }

    Reveal {
        p: root; index: 0; dy: 10
        RowLayout {
            Layout.fillWidth: true; spacing: 20
            // scrolling works anywhere in the window (mouse wheel, two fingers on the touchpad), also over the sidebar
            WheelHandler {
                onWheel: event => {
                    const d = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y * 0.6
                    pages.scroll = Math.max(0, Math.min(pages.maxScroll(), pages.scroll - d))
                }
            }

            // ---------- sidebar ----------
            Item {
                Layout.preferredWidth: 200; Layout.preferredHeight: root.pages.length * 44; Layout.alignment: Qt.AlignTop
                Rectangle {
                    width: parent.width; height: 40; radius: 11; color: Theme.accent
                    y: root.page * 44
                    Behavior on y { NumberAnimation { duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
                }
                Repeater {
                    model: root.pages
                    delegate: Item {
                        required property var modelData
                        required property int index
                        y: index * 44; width: parent.width; height: 40
                        RowLayout {
                            anchors { fill: parent; leftMargin: 14 }
                            spacing: 12
                            Icon { Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter; name: modelData.icon; size: 20; color: root.page === index ? Theme.panelBg : Theme.on_surface_variant
                                   Behavior on color { ColorAnimation { duration: 220 } } }
                            Text { textFormat: Text.PlainText; text: modelData.name; font.family: Theme.mono; font.pixelSize: 12; font.bold: true
                                   color: root.page === index ? Theme.panelBg : Theme.on_surface
                                   Behavior on color { ColorAnimation { duration: 220 } } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.page = index }
                    }
                }
            }

            // ---------- pages ----------
            Item {
                id: pages
                Layout.fillWidth: true; Layout.preferredHeight: 580; clip: true
                // a page taller than the window scrolls with the mouse wheel
                property real scroll: 0
                function maxScroll() {
                    for (let i = 0; i < children.length; i++) if (children[i].on) return Math.max(0, children[i].implicitHeight - height + 8)
                    return 0
                }
                Connections { target: root; function onPageChanged() { pages.scroll = 0 } }
                Behavior on scroll { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Rectangle {   // scroll bar, only on a page that needs it
                    visible: pages.maxScroll() > 0
                    x: parent.width - 5; width: 3; radius: 1.5; color: Qt.alpha(Theme.on_surface, 0.3); z: 5
                    height: Math.max(30, parent.height * parent.height / (parent.height + pages.maxScroll()))
                    y: pages.maxScroll() > 0 ? (parent.height - height) * pages.scroll / pages.maxScroll() : 0
                }

                SettingPage { idx: 0; current: root.page; title: "Appearance"
                    SettingRow { title: "Theme"; hint: "Colours come from the wallpaper, in a dark or a light variant"
                        SettingChips { model: [{ label: "Dark", value: "dark" }, { label: "Light", value: "light" }]; current: Settings.themeMode; onPicked: v => root.applyTheme(v) } }
                    SettingRow { title: "Wallpaper"; hint: "Choose one from ~/Pictures/Wallpapers"
                        SettingButton { label: "Choose…"; accent: true; onClicked: root.open("wallpaper") } }
                    SettingRow { title: "Animated wallpaper"; hint: "Videos from ~/Videos/Hidamari or ~/Videos/Wallpapers. They always pause in fullscreen and while locked."
                        SettingChips { chipW: 110; model: [{ label: "Pause on battery", value: false }, { label: "Always play", value: true }]
                                       current: Settings.liveOnBattery; onPicked: v => Settings.set("liveOnBattery", v) } }
                }
                SettingPage { idx: 1; current: root.page; title: "Desktop"
                    SettingRow { title: "Dock"; hint: "Spotify, Chrome, Discord and VS Code at the bottom edge; it slides up when you touch the edge"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.dock; onPicked: v => Settings.set("dock", v) } }
                    SettingRow { title: "Desktop widgets"; hint: "Clock, battery and the playing track on the bare desktop"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.widgets; onPicked: v => Settings.set("widgets", v) } }
                    SettingRow { title: "Music bars"; hint: "Live audio bars above the music widget while something plays"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.visualizer; onPicked: v => Settings.set("visualizer", v) } }
                    SettingRow { title: "Wallpaper change"; hint: "How a new wallpaper arrives"
                        SettingChips { chipW: 58; model: [{ label: "Circle", value: "circle" }, { label: "Fade", value: "fade" }, { label: "Wipe", value: "wipe" }, { label: "Zoom", value: "zoom" }, { label: "Mix", value: "random" }]
                                       current: Settings.wallpaperEffect; onPicked: v => Settings.set("wallpaperEffect", v) } }
                    SettingRow { title: "Click effect"; hint: "A ring at every left click, handy for screen recordings"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.clickEffect; onPicked: v => Settings.set("clickEffect", v) } }
                    SettingRow { title: "Bar position"; hint: "Panels still open from the top"
                        SettingChips { chipW: 66; model: [{ label: "Top", value: "top" }, { label: "Bottom", value: "bottom" }]
                                       current: Settings.barPosition; onPicked: v => Settings.set("barPosition", v) } }
                    SettingRow { title: "Hide the bar"; hint: "It slides away and returns when the pointer touches the screen edge"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.barAutohide; onPicked: v => Settings.set("barAutohide", v) } }
                    SettingRow { title: "Bar modules"; hint: "Click to show or hide"
                        Flow {
                            spacing: 6; width: 360
                            Repeater {
                                model: ["search", "bell", "workspaces", "media", "clock", "weather", "tray", "status"]
                                delegate: Rectangle {
                                    required property string modelData
                                    readonly property bool on: Settings.barHidden.indexOf(modelData) < 0
                                    implicitWidth: lbl.implicitWidth + 20; implicitHeight: 28; radius: 9
                                    color: on ? Theme.accent : Theme.card
                                    border.width: on ? 0 : 1; border.color: Theme.outline_variant
                                    Behavior on color { ColorAnimation { duration: 160 } }
                                    Text { id: lbl; anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData; font.family: Theme.mono; font.pixelSize: 11; font.bold: true
                                           color: parent.on ? Theme.panelBg : Theme.on_surface_variant }
                                    MouseArea { anchors.fill: parent
                                        onClicked: { const h = Settings.barHidden.filter(x => x !== modelData); if (parent.on) h.push(modelData); Settings.set("barHidden", h) } }
                                }
                            }
                        } }
                    SettingRow { title: "Dock apps"; hint: "Add, remove and reorder the apps in the dock (also the + in the dock)"
                        SettingButton { label: "Edit…"; accent: true; onClicked: root.open("dockapps") } }
                }
                SettingPage { idx: 2; current: root.page; title: "Display"
                    SettingRow { title: "Resolution, refresh rate and scale"; hint: "Applies at once and is remembered"
                        SettingButton { label: "Open"; accent: true; onClicked: root.open("display") } }
                }
                SettingPage { idx: 3; current: root.page; title: "Sound"
                    SettingRow { title: "Volume"; hint: Audio.sink ? Audio.sink.description : ""
                        MSlider { implicitWidth: 260; knob: true; value: Math.min(1, Audio.volume)
                                  onMoved: v => Audio.setVolume(v) } }
                    SettingRow { title: "Mixer"; hint: "Output and input device, volume per app"
                        SettingButton { label: "Open"; accent: true; onClicked: root.open("volume") } }
                    SettingRow { title: "Music and equalizer"
                        SettingButton { label: "Open"; onClicked: root.open("music") } }
                }
                SettingPage { idx: 4; current: root.page; title: "Network"
                    SettingRow { title: "Wi-Fi"
                        SettingChips { chipW: 64; model: [{ label: "On", value: true }, { label: "Off", value: false }]; current: Networking.wifiEnabled; onPicked: v => Networking.wifiEnabled = v } }
                    SettingRow { title: "Bluetooth"; visible: Bluetooth.defaultAdapter !== null
                        SettingChips { chipW: 64; model: [{ label: "On", value: true }, { label: "Off", value: false }]; current: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                                       onPicked: v => { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = v } } }
                    SettingRow { title: "Network panel"; hint: "Overview, scan and connect"
                        SettingButton { label: "Open"; accent: true; onClicked: root.open("network") } }
                    SettingRow { title: "All options"; hint: "Hidden networks, VPN, connection information"
                        SettingButton { label: "Menu"; onClicked: { const it = SystemTray.items.values.find(i => i.id === "nm-applet"); if (it) { Popups.trayItem = it; root.open("traymenu") } } }
                        SettingButton { label: "Edit connections"; onClicked: { Popups.close(); Quickshell.execDetached(["nm-connection-editor"]) } } }
                }
                SettingPage { idx: 5; current: root.page; title: "Keyboard"
                    SettingRow { title: "Layouts"; hint: "The first one is the default. At least one stays."
                        Flow {
                            Layout.preferredWidth: 330; spacing: 6
                            Repeater {
                                model: [{ c: "us", n: "English (US)" }, { c: "de", n: "German" }, { c: "fr", n: "French" }, { c: "es", n: "Spanish" }, { c: "it", n: "Italian" }, { c: "pl", n: "Polish" }]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool on: root.layouts.indexOf(modelData.c) >= 0
                                    width: lt.implicitWidth + 22; height: 30; radius: 9
                                    color: on ? Theme.accent : (ma.containsMouse ? Theme.cardHigh : Theme.cardHigh)
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                    Text { id: lt; anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData.n; color: parent.on ? Theme.panelBg : Theme.on_surface
                                           font.family: Theme.mono; font.pixelSize: 11; font.bold: true }
                                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { const l = root.layouts.slice(); const i = l.indexOf(modelData.c)
                                                     if (i >= 0) { if (l.length > 1) l.splice(i, 1) } else l.push(modelData.c)
                                                     root.layouts = l } }
                                }
                            }
                        } }
                    SettingRow { title: "Switch with"; hint: "Super+Space always works"
                        SettingChips { chipW: 96; model: [{ label: "Alt+Shift", value: "grp:alt_shift_toggle" }, { label: "Super+Space", value: "" }]; current: root.kbSwitch; onPicked: v => root.kbSwitch = v } }
                    SettingRow { title: "Apply"; hint: "Active layout now: " + Keyboard.name
                        SettingButton { label: "Apply"; accent: true; onClicked: root.applyKeyboard() } }
                }
                SettingPage { idx: 6; current: root.page; title: "Mouse & touchpad"
                    SettingRow { title: "Natural scrolling"; hint: "Touchpad: content follows your fingers"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.naturalScroll; onPicked: v => root.setInput("naturalScroll", v) } }
                    SettingRow { title: "Tap to click"; hint: "Touchpad"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.tapToClick; onPicked: v => root.setInput("tapToClick", v) } }
                    SettingRow { title: "Pause while typing"; hint: "Touchpad ignores your palm"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.disableTyping; onPicked: v => root.setInput("disableTyping", v) } }
                    SettingRow { title: "Pointer speed"; hint: "Mouse and touchpad"
                        SettingChips { chipW: 70; model: [{ label: "Slow", value: -0.4 }, { label: "Normal", value: 0 }, { label: "Fast", value: 0.4 }, { label: "Faster", value: 0.8 }]
                                       current: Settings.pointerSpeed; onPicked: v => root.setInput("pointerSpeed", v) } }
                    SettingRow { title: "Scroll speed"; hint: "Touchpad"
                        SettingChips { chipW: 70; model: [{ label: "Slow", value: 0.5 }, { label: "Normal", value: 1 }, { label: "Fast", value: 1.6 }, { label: "Faster", value: 2.4 }]
                                       current: Settings.scrollSpeed; onPicked: v => root.setInput("scrollSpeed", v) } }
                    SettingRow { title: "Mouse acceleration"; hint: "Flat = the same distance every time"
                        SettingChips { chipW: 80; model: [{ label: "Adaptive", value: "adaptive" }, { label: "Flat", value: "flat" }]
                                       current: Settings.accelProfile; onPicked: v => root.setInput("accelProfile", v) } }
                    SettingRow { title: "Key repeat"; hint: "How fast a held key repeats"
                        SettingChips { chipW: 70; model: [{ label: "Slow", value: 15 }, { label: "Normal", value: 25 }, { label: "Fast", value: 40 }]
                                       current: Settings.repeatRate; onPicked: v => root.setInput("repeatRate", v) } }
                }
                SettingPage { idx: 7; current: root.page; title: "Night light"
                    SettingRow { title: "Night light"; hint: "Warms the screen colour"
                        SettingChips { chipW: 64; model: [{ label: "On", value: true }, { label: "Off", value: false }]; current: root.nlOn
                                       onPicked: v => { root.nlOn = v; Quickshell.execDetached(["nightlight", v ? "on" : "off"]) } } }
                    SettingRow { title: "Colour temperature"; hint: Math.round(root.nlTemp) + " K - lower is warmer"
                        MSlider { implicitWidth: 260; knob: true; value: (root.nlTemp - 2000) / 4000; fill: Theme.accent2
                                  onMoved: v => { root.nlTemp = 2000 + v * 4000; nlSet.restart() } } }
                    SettingRow { title: "Presets"
                        SettingChips { chipW: 74; model: [{ label: "Warm", value: 3000 }, { label: "Soft", value: 3800 }, { label: "Mild", value: 4600 }]
                                       current: Math.abs(root.nlTemp - 3000) < 50 ? 3000 : Math.abs(root.nlTemp - 3800) < 50 ? 3800 : Math.abs(root.nlTemp - 4600) < 50 ? 4600 : -1
                                       onPicked: v => { root.nlTemp = v; nlSet.restart() } } }
                }
                SettingPage { idx: 8; current: root.page; title: "Power & lock"
                    SettingRow { title: "Lock after"; hint: "Minutes without input"
                        SettingChips { chipW: 66; model: [{ label: "Never", value: 0 }, { label: "3", value: 3 }, { label: "5", value: 5 }, { label: "10", value: 10 }, { label: "15", value: 15 }]
                                       current: Settings.lockMinutes; onPicked: v => Settings.set("lockMinutes", v) } }
                    SettingRow { title: "Screen off while locked"; hint: "Minutes without input"
                        SettingChips { chipW: 66; model: [{ label: "Never", value: 0 }, { label: "3", value: 3 }, { label: "6", value: 6 }, { label: "10", value: 10 }]
                                       current: Settings.screenOffMinutes; onPicked: v => Settings.set("screenOffMinutes", v) } }
                    SettingRow { title: "Suspend on battery"; hint: "Minutes without input, only while unplugged"
                        SettingChips { chipW: 66; model: [{ label: "Never", value: 0 }, { label: "10", value: 10 }, { label: "15", value: 15 }, { label: "30", value: 30 }]
                                       current: Settings.suspendMinutes; onPicked: v => Settings.set("suspendMinutes", v) } }
                    SettingRow { title: "Power saver at 20 %"; hint: "Switches the profile automatically and restores it when charging"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.autoSaver; onPicked: v => Settings.set("autoSaver", v) } }
                    SettingRow { title: "Battery health"; hint: Battery.health > 0 ? "Holds " + Battery.health + " % of its original capacity (" + Battery.cycles + " charge cycles)" : "Not reported by this battery"
                        SettingButton { label: Battery.health > 0 ? Battery.health + " %" : "n/a" } }
                    SettingRow { title: "Lock now"; hint: "Super+L"
                        SettingButton { label: "Lock"; accent: true; onClicked: { Popups.close(); Quickshell.execDetached(["quickshell", "ipc", "call", "shell", "lock"]) } } }
                    SettingRow { title: "Power panel"; hint: "Battery, brightness, profile, session"
                        SettingButton { label: "Open"; onClicked: root.open("power") } }
                }
                SettingPage { idx: 9; current: root.page; title: "Notifications"
                    SettingRow { title: "Muted apps"; hint: "No pop-up from these; they stay in the history. Click one to let it speak again."
                        Flow {
                            Layout.preferredWidth: 300; spacing: 6
                            Text { visible: Settings.mutedApps.length === 0; textFormat: Text.PlainText; text: "None. Mute an app with the bell on its card in the notification center."
                                   color: Theme.outline; font.family: Theme.mono; font.pixelSize: 10; wrapMode: Text.Wrap; width: 300 }
                            Repeater {
                                model: Settings.mutedApps
                                delegate: Rectangle {
                                    required property string modelData
                                    height: 28; width: mt.implicitWidth + 30; radius: 9; color: mm.containsMouse ? Theme.error : Theme.cardHigh
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Text { id: mt; anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData + "  \u00d7"
                                           color: mm.containsMouse ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11; font.bold: true }
                                    MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; onClicked: Settings.set("mutedApps", Settings.mutedApps.filter(a => a !== modelData)) }
                                }
                            }
                        } }
                    SettingRow { title: "Popup duration"; hint: "Apps that set their own time keep it"
                        SettingChips { chipW: 60; model: [{ label: "3 s", value: 3 }, { label: "6 s", value: 6 }, { label: "10 s", value: 10 }, { label: "15 s", value: 15 }]
                                       current: Settings.popupSeconds; onPicked: v => Settings.set("popupSeconds", v) } }
                    SettingRow { title: "Do not disturb"; hint: "Hides popups, they still land in the center"
                        SettingChips { chipW: 64; model: [{ label: "On", value: true }, { label: "Off", value: false }]; current: Popups.dnd; onPicked: v => Popups.dnd = v } }
                    SettingRow { title: "History"; hint: NotifHistory.items.count + " saved"
                        SettingButton { label: "Clear"; onClicked: NotifHistory.clear() }
                        SettingButton { label: "Open"; onClicked: root.open("notifications") } }
                }
                SettingPage { idx: 10; current: root.page; title: "Calendar"
                    SettingRow { title: "Calendar link (iCal)"; hint: Events.configured ? "Source found, " + Events.upcoming.length + " upcoming events" : "No source yet. Paste a private iCal link."
                        Rectangle {
                            implicitWidth: 300; implicitHeight: 32; radius: 10; color: Theme.cardHigh
                            TextInput { id: urlIn; anchors { fill: parent; leftMargin: 12; rightMargin: 12 } verticalAlignment: TextInput.AlignVCenter; clip: true
                                        echoMode: TextInput.Password; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11; selectionColor: Theme.accent
                                        onAccepted: { root.saveCalendar(text); text = "" } }
                            Text { visible: urlIn.text === ""; anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } textFormat: Text.PlainText
                                   text: "https://…  (kept private)"; color: Theme.outline; font.family: Theme.mono; font.pixelSize: 11 }
                        }
                        SettingButton { label: "Save"; accent: true; onClicked: { root.saveCalendar(urlIn.text); urlIn.text = "" } } }
                    SettingRow { title: "Reload"; hint: "Re-read the calendar now (otherwise every 30 minutes)"
                        SettingButton { label: "Reload"; onClicked: Events.reload() } }
                    SettingRow { title: "Calendar panel"
                        SettingButton { label: "Open"; onClicked: root.open("calendar") } }
                }
                SettingPage { idx: 11; current: root.page; title: "Shortcuts"
                    SettingRow { title: "All shortcuts"; hint: "Every key combination of this desktop, grouped. Also on Super+F1"
                        SettingButton { label: "Open"; accent: true; onClicked: root.open("shortcuts") } }
                }
                SettingPage { idx: 12; current: root.page; title: "About"
                    SettingRow { title: "Software"; hint: root.hyprVersion }
                    SettingRow { title: "Configuration"; hint: "~/dotfiles  (Hyprland, Quickshell, matugen)"
                        SettingButton { label: "Open folder"; onClicked: { Popups.close(); Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/dotfiles"]) } } }
                    SettingRow { title: "Reload the shell"; hint: "Quickshell reloads itself when its files change"
                        SettingButton { label: "Reload"; onClicked: Quickshell.reload(true) } }
                }
            }
        }
    }
}
