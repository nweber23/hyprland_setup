import Quickshell
import QtQuick
import QtQuick.Layouts

// Quick menu: everything that used to be a row of little icons in the bar, as tiles. Panels open on a click,
// switches (keep awake, game mode, focus) light up while they are on.
Panel {
    id: root
    name: "quick"
    backdrop: "Dots"
    panelWidth: 430

    function open(name) { Popups.toggle(name, Popups.screenName, Popups.anchorX) }

    Reveal {
        p: root; index: 0; dy: 8
        Text { textFormat: Text.PlainText; text: "Quick menu"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
        GridLayout {
            Layout.fillWidth: true
            columns: 4; rowSpacing: 8; columnSpacing: 8
            ToggleTile { Layout.fillWidth: true; icon: "timer"; label: "Timer"; onToggled: root.open("tools") }
            ToggleTile { Layout.fillWidth: true; icon: "photo_camera"; label: "Capture"; onToggled: root.open("capture") }
            ToggleTile { Layout.fillWidth: true; icon: "desktop_windows"; label: "Display"; onToggled: root.open("display") }
            ToggleTile { Layout.fillWidth: true; icon: "cast"; label: "Projection"; onToggled: root.open("projector") }
            ToggleTile { Layout.fillWidth: true; icon: "hourglass_top"; label: "Screen time"; onToggled: root.open("screentime") }
            ToggleTile { Layout.fillWidth: true; icon: "monitor_heart"; label: "System"; onToggled: root.open("sysmon") }
            ToggleTile { Layout.fillWidth: true; icon: "keyboard_alt"; label: "Keyboard"; onToggled: { Popups.close(); Quickshell.execDetached(["osk"]) } }
            ToggleTile { Layout.fillWidth: true; icon: "settings"; label: "Settings"; onToggled: root.open("settings") }
            ToggleTile { Layout.fillWidth: true; icon: "local_cafe"; label: "Stay awake"; on: Popups.keepAwake; onToggled: Popups.keepAwake = !Popups.keepAwake }
            ToggleTile { Layout.fillWidth: true; icon: "sports_esports"; label: "Game mode"; on: Popups.gameMode
                         onToggled: Quickshell.execDetached(["hyprctl", "eval", "qsGameMode(" + (Popups.gameMode ? "false" : "true") + ")"]) }
            ToggleTile { Layout.fillWidth: true; icon: "self_improvement"; label: "Focus"; on: Popups.focusMode
                         onToggled: { Popups.close(); Popups.setFocus(!Popups.focusMode) } }
            ToggleTile { Layout.fillWidth: true; icon: "keyboard_command_key"; label: "Shortcuts"; onToggled: root.open("shortcuts") }
        }
    }
}
