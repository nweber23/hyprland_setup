//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    // Keybinds call:  quickshell ipc call shell toggle <panel>
    IpcHandler {
        target: "shell"
        function toggle(name: string): void {
            const m = Hyprland.focusedMonitor
            if (m) Popups.toggle(name, m.name, m.width / m.scale / 2)
        }
    }
    Process { running: true; command: ["screentime-daemon"] }
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
            Launcher { screen: perScreen.modelData; screenName: perScreen.modelData.name }
            PowerPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
            MusicPanel { screen: perScreen.modelData; screenName: perScreen.modelData.name; screenWidth: perScreen.modelData.width }
        }
    }
}
