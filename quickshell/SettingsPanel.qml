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
        { name: "Appearance", icon: "palette" }, { name: "Display", icon: "desktop_windows" }, { name: "Sound", icon: "volume_up" },
        { name: "Network", icon: "wifi" }, { name: "Keyboard", icon: "keyboard" }, { name: "Night light", icon: "nightlight" },
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
    onShownChanged: if (shown) { kbRead.running = true; kbOpt.running = true; nlRead.running = true; ver.running = true }

    Timer { id: nlSet; interval: 350; onTriggered: Quickshell.execDetached(["nightlight", "set", String(Math.round(root.nlTemp))]) }

    function applyTheme(mode) {
        Settings.set("themeMode", mode)
        if (wallpaper !== "") Quickshell.execDetached(["env", "THEME_MODE=" + mode, "set-wallpaper", wallpaper])
    }
    // the layouts come from a fixed list, so nothing user-typed ends up in the Lua text
    function applyKeyboard() {
        const lua = 'hl.config({ input = { kb_layout = "' + layouts.join(",") + '", kb_options = "' + kbSwitch + '" } })\n'
        kbFile.setText("-- Written by the shell's settings; loaded last by hyprland.lua.\n" + lua)
        Quickshell.execDetached(["hyprctl", "eval", lua])
        refreshKb.restart()
    }
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

                SettingPage { idx: 0; current: root.page; title: "Appearance"
                    SettingRow { title: "Theme"; hint: "Colours come from the wallpaper, in a dark or a light variant"
                        SettingChips { model: [{ label: "Dark", value: "dark" }, { label: "Light", value: "light" }]; current: Settings.themeMode; onPicked: v => root.applyTheme(v) } }
                    SettingRow { title: "Dock"; hint: "Spotify, Chrome, Discord and VS Code at the bottom edge; it slides up when you touch the edge"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.dock; onPicked: v => Settings.set("dock", v) } }
                    SettingRow { title: "Desktop widgets"; hint: "Clock, battery and the playing track on the bare desktop"
                        SettingChips { chipW: 66; model: [{ label: "Off", value: false }, { label: "On", value: true }]
                                       current: Settings.widgets; onPicked: v => Settings.set("widgets", v) } }
                    SettingRow { title: "Wallpaper"; hint: "Choose one from ~/Pictures/Wallpapers"
                        SettingButton { label: "Choose…"; accent: true; onClicked: root.open("wallpaper") } }
                    SettingRow { title: "Animated wallpaper"; hint: "Videos from ~/Videos/Hidamari or ~/Videos/Wallpapers. They always pause in fullscreen and while locked."
                        SettingChips { chipW: 110; model: [{ label: "Pause on battery", value: false }, { label: "Always play", value: true }]
                                       current: Settings.liveOnBattery; onPicked: v => Settings.set("liveOnBattery", v) } }
                }
                SettingPage { idx: 1; current: root.page; title: "Display"
                    SettingRow { title: "Resolution, refresh rate and scale"; hint: "Applies at once and is remembered"
                        SettingButton { label: "Open"; accent: true; onClicked: root.open("display") } }
                }
                SettingPage { idx: 2; current: root.page; title: "Sound"
                    SettingRow { title: "Volume"; hint: Audio.sink ? Audio.sink.description : ""
                        MSlider { implicitWidth: 260; knob: true; value: Math.min(1, Audio.volume)
                                  onMoved: v => Audio.setVolume(v) } }
                    SettingRow { title: "Mixer"; hint: "Output and input device, volume per app"
                        SettingButton { label: "Open"; accent: true; onClicked: root.open("volume") } }
                    SettingRow { title: "Music and equalizer"
                        SettingButton { label: "Open"; onClicked: root.open("music") } }
                }
                SettingPage { idx: 3; current: root.page; title: "Network"
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
                SettingPage { idx: 4; current: root.page; title: "Keyboard"
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
                SettingPage { idx: 5; current: root.page; title: "Night light"
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
                SettingPage { idx: 6; current: root.page; title: "Power & lock"
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
                SettingPage { idx: 7; current: root.page; title: "Notifications"
                    SettingRow { title: "Popup duration"; hint: "Apps that set their own time keep it"
                        SettingChips { chipW: 60; model: [{ label: "3 s", value: 3 }, { label: "6 s", value: 6 }, { label: "10 s", value: 10 }, { label: "15 s", value: 15 }]
                                       current: Settings.popupSeconds; onPicked: v => Settings.set("popupSeconds", v) } }
                    SettingRow { title: "Do not disturb"; hint: "Hides popups, they still land in the center"
                        SettingChips { chipW: 64; model: [{ label: "On", value: true }, { label: "Off", value: false }]; current: Popups.dnd; onPicked: v => Popups.dnd = v } }
                    SettingRow { title: "History"; hint: NotifHistory.items.count + " saved"
                        SettingButton { label: "Clear"; onClicked: NotifHistory.clear() }
                        SettingButton { label: "Open"; onClicked: root.open("notifications") } }
                }
                SettingPage { idx: 8; current: root.page; title: "Calendar"
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
                SettingPage { idx: 9; current: root.page; title: "Shortcuts"
                    GridLayout {
                        Layout.fillWidth: true; columns: 2; columnSpacing: 12; rowSpacing: 6
                        Repeater {
                            model: [["Super+R", "Launcher"], ["Super+Q", "Terminal"], ["Super+C", "Close window"], ["Super+B", "Browser"], ["Super+W", "Wallpaper"],
                                    ["Super+T", "Screen time"], ["Super+X", "Screenshot / recording"], ["Super+Shift+V", "Clipboard history"], ["Super+L", "Lock"],
                                    ["Super+Space", "Next keyboard layout"], ["Super+Tab", "Next workspace"], ["Super+1..9", "Go to workspace"],
                                    ["Super+Shift+1..9", "Move window there"], ["Super+Arrows", "Focus"], ["Super+Shift+N", "Night light"], ["Super+Shift+R", "Record region"], ["Super+M", "Log out"]]
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; implicitHeight: 36; radius: 10; color: Theme.card
                                RowLayout { anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                    Text { Layout.preferredWidth: 130; textFormat: Text.PlainText; text: modelData[0]; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 11; font.bold: true }
                                    Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: modelData[1]; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11 } }
                            }
                        }
                    }
                }
                SettingPage { idx: 10; current: root.page; title: "About"
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
