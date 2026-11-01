import Quickshell
import QtQuick
import QtQuick.Layouts

// Overview of all key combinations (Super+F1), read from Shortcuts.
Panel {
    id: root
    name: "shortcuts"
    backdrop: "Dots"
    panelWidth: 1260
    centered: true

    Reveal {
        p: root; index: 0; dy: 8
        RowLayout {
            Layout.fillWidth: true
            Icon { name: "keyboard"; size: 22; color: Theme.accent }
            Text { textFormat: Text.PlainText; text: "Shortcuts"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 16; font.bold: true }
            Item { Layout.fillWidth: true }
            Text { textFormat: Text.PlainText; text: "Super is the Windows key"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
        }
    }
    Reveal {
        p: root; index: 1; dy: 12
        GridLayout {
            Layout.fillWidth: true
            columns: 3; columnSpacing: 24; rowSpacing: 18
            Repeater {
                model: Shortcuts.groups
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.alignment: Qt.AlignTop; Layout.fillWidth: true; Layout.preferredWidth: 1
                    spacing: 6
                    RowLayout {
                        spacing: 6
                        Icon { name: modelData.icon; size: 17; color: Theme.accent2 }
                        Text { textFormat: Text.PlainText; text: modelData.title; color: Theme.accent2; font.family: Theme.mono; font.pixelSize: 12; font.bold: true }
                    }
                    Repeater {
                        model: modelData.items
                        delegate: ShortcutRow { required property var modelData; keys: modelData[0]; what: modelData[1] }
                    }
                }
            }
        }
    }
}
