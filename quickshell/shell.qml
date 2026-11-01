//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick

ShellRoot {
    Component.onCompleted: Battery.init()
    // Keybinds call:  quickshell ipc call shell toggle <panel>
    IpcHandler {
        target: "shell"
        function toggle(name: string): void {
            const m = Hyprland.focusedMonitor
            if (m) Popups.toggle(name, m.name, m.width / m.scale / 2)
        }
        function lock(): void { lockScreen.lock() }
        function focus(): void { Popups.setFocus(!Popups.focusMode) }   // focus mode: no bar, no notifications, a 25 minute countdown
        function launcher(query: string): void {   // open the launcher with a ready-made query
            Popups.launcherPrefill = query
            const m = Hyprland.focusedMonitor
            if (m) Popups.toggle("launcher", m.name, m.width / m.scale / 2)
        }
        function dock(): void { Popups.dockPinned = !Popups.dockPinned }   // hold the dock open / let it hide again
        function switcherConfirm(): void {
            if (Popups.current === "switcher") Popups.switchConfirm(); else Popups.earlyConfirm = Date.now()
        }
        function switcherOpen(steps: int): void {   // held Alt/Super: open with the Tab presses counted so far
            const m = Hyprland.focusedMonitor
            if (!m || Popups.current === "switcher") return
            Popups.initSteps = steps - 1
            Popups.toggle("switcher", m.name, 0)
            if (Date.now() - Popups.earlyConfirm < 300) { Popups.earlyConfirm = 0; Popups.switchConfirm() }
        }
        function switcher(dir: int): void {   // Alt+Tab / Super+Tab: open the window overview, or move on while it is open
            if (Popups.current === "switcher") { Popups.switchStep(dir); return }
            const m = Hyprland.focusedMonitor
            if (!m) return
            Popups.toggle("switcher", m.name, 0)
            // the release can overtake the open (two separate processes): then it is applied right after opening
            if (Date.now() - Popups.earlyConfirm < 300) { Popups.earlyConfirm = 0; Popups.switchConfirm() }
        }
        function tray(index: int): void {   // open the menu of tray item <index> (for testing without a mouse)
            const it = SystemTray.items.values[index]; const m = Hyprland.focusedMonitor
            if (it && m) { Popups.trayItem = it; Popups.toggle("traymenu", m.name, m.width / m.scale - 120) }
        }
        function charge(plugged: bool): void { chargeOsd.play(plugged) }   // preview: quickshell ipc call shell charge true
    }
    Process { running: true; command: ["screentime-daemon"] }
    Process { running: true; command: ["usb-mount"] }       // mounts USB sticks when plugged in, with an Open/Eject notification
    Process { running: true; command: ["sleep-lock"] }   // locks the screen before any suspend (lid, idle)
    // Feeds the clipboard history: clip-store runs once per newly copied text.
    Process { running: true; command: ["wl-paste", "--type", "text", "--watch", "clip-store"] }
    Notifications {}
    Lock { id: lockScreen }
    Osd {}
    ChargeOsd { id: chargeOsd }
    PolkitDialog {}
    Variants {
        model: Quickshell.screens
        Wallpaper {
            required property var modelData
            screen: modelData
        }
    }
    Variants {
        model: Quickshell.screens
        DesktopWidgets {
            required property var modelData
            screen: modelData
        }
    }
    Variants {
        model: Quickshell.screens
        FocusMode {
            required property var modelData
            screen: modelData
        }
    }
    Variants {
        model: Quickshell.screens
        Dock {
            required property var modelData
            screen: modelData
        }
    }
    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property var modelData
            Bar { screen: perScreen.modelData }
            CalendarPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            NetworkPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            WallpaperPicker { screen: perScreen.modelData; screenName: perScreen.modelData.name }
            ScreenTimePanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            DisplayPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            ClipboardPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name }
            WindowSwitcher { screen: perScreen.modelData; screenName: perScreen.modelData.name }
            WorkspaceOverview { screen: perScreen.modelData; screenName: perScreen.modelData.name }
            TrayMenu { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            NotificationCenter { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            VolumePanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            CapturePanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            ToolsPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            ShortcutsPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            ProjectorPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            SettingsPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            SysMonPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            Launcher { screen: perScreen.modelData; screenName: perScreen.modelData.name }
            PowerPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            MusicPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
        }
    }
}
