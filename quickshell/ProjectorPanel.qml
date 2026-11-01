import Quickshell
import QtQuick
import QtQuick.Layouts

// Projection menu (Super+P): what the screens show. The work is done by qsProjector in hyprland.lua.
Panel {
    id: root
    name: "projector"
    backdrop: "Aurora"
    panelWidth: 640
    centered: true

    function setMode(m) {
        Popups.close()
        Quickshell.execDetached(["hyprctl", "eval", "qsProjector(\"" + m + "\")"])
    }

    Reveal {
        p: root; index: 0; dy: 8
        RowLayout {
            Layout.fillWidth: true
            Icon { name: "cast"; size: 22; color: Theme.accent }
            Text { textFormat: Text.PlainText; text: "Projection"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 16; font.bold: true }
            Item { Layout.fillWidth: true }
            Text { textFormat: Text.PlainText; text: Quickshell.screens.length > 1 ? "" : "Connect a second screen first"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
        }
    }
    Reveal {
        p: root; index: 1; dy: 12; back: true
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            CaptureTile { icon: "laptop_chromebook"; label: "Laptop only"; onActivated: root.setMode("first") }
            CaptureTile { icon: "content_copy"; label: "Duplicate"; onActivated: root.setMode("mirror") }
            CaptureTile { icon: "desktop_windows"; label: "Extend"; onActivated: root.setMode("extend") }
            CaptureTile { icon: "tv"; label: "Second only"; onActivated: root.setMode("second") }
        }
    }
    Reveal {
        p: root; index: 2; dy: 8
        Text { Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText
               text: "Extend returns to the layout saved in the display panel. With one screen switched off, its windows move to the other one."
               color: Theme.outline; font.family: Theme.mono; font.pixelSize: 10 }
    }
}
