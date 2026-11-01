import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Focus mode: the bar goes away, notifications are silenced and a 25 minute countdown runs. This is the small pill that
// stays while it lasts; click it to stop early. Switched with Super+Z (quickshell ipc call shell focus).
PanelWindow {
    id: win
    visible: Popups.focusMode
    anchors { top: true }
    margins.top: 8
    implicitWidth: pill.width; implicitHeight: pill.height
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-focus"

    Rectangle {
        id: pill
        width: row.implicitWidth + 28; height: 34; radius: 17
        color: Qt.alpha(Theme.surface_container, 0.85)
        border.width: 1; border.color: Qt.alpha(Theme.accent, 0.6)
        RowLayout {
            id: row; anchors.centerIn: parent; spacing: 8
            Icon { name: "self_improvement"; size: 18; color: Theme.accent }
            Text { textFormat: Text.PlainText; text: "Focus  " + Tools.fmt(Tools.left)
                   color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12; font.bold: true }
        }
        MouseArea { anchors.fill: parent; onClicked: Popups.setFocus(false) }
    }
}
