import QtQuick
import QtQuick.Layouts

// Context menu of the tray item that was clicked (Popups.trayItem), drawn in the shell's own style.
Panel {
    id: root
    name: "traymenu"
    panelWidth: 270
    pad: 8
    animateHeight: true

    Text { visible: !Popups.trayItem || !Popups.trayItem.hasMenu; Layout.margins: 8; textFormat: Text.PlainText
           text: Popups.trayItem ? Popups.trayItem.title : ""; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
    TrayMenuList {
        Layout.fillWidth: true
        handle: Popups.trayItem && Popups.trayItem.hasMenu ? Popups.trayItem.menu : null
        onPicked: Popups.close()
    }
}
