//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick

ShellRoot {
    // Keybinds call:  quickshell ipc call shell toggle <panel>
    IpcHandler {
        target: "shell"
        function toggle(name: string): void {
            const m = Hyprland.focusedMonitor
            if (m) Popups.toggle(name, m.name, m.width / m.scale / 2)
        }
        function lock(): void { lockScreen.lock() }
        function tray(index: int): void {   // open the menu of tray item <index> (for testing without a mouse)
            const it = SystemTray.items.values[index]; const m = Hyprland.focusedMonitor
            if (it && m) { Popups.trayItem = it; Popups.toggle("traymenu", m.name, m.width / m.scale - 120) }
        }
        function charge(plugged: bool): void { chargeOsd.play(plugged) }   // preview: quickshell ipc call shell charge true
    }
    Process { running: true; command: ["screentime-daemon"] }
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
            TrayMenu { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            NotificationCenter { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            Launcher { screen: perScreen.modelData; screenName: perScreen.modelData.name }
            PowerPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            MusicPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
        }
    }
}
