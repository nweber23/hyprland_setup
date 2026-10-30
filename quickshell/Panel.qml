import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Popup card that hangs under the bar. Content goes in as children (a ColumnLayout).
// Closes when the user clicks anywhere else.
PanelWindow {
    id: win
    required property string name
    // Plain values from the owner. Reading `screen` here would loop: shown -> visible -> screen -> shown.
    property string screenName: ""
    property real screenWidth: 1920
    property real panelWidth: 380
    default property alias content: body.data
    readonly property bool shown: Popups.current === name && Popups.screenName === screenName

    visible: shown || card.opacity > 0.01
    anchors { top: true; left: true }
    margins {
        top: 8 + 34 + 8
        left: Math.max(12, Math.min(screenWidth - panelWidth - 12, Popups.anchorX - panelWidth / 2))
    }
    implicitWidth: panelWidth
    implicitHeight: card.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand   // panels with text fields get keys after a click

    HyprlandFocusGrab {
        windows: [win]
        active: win.shown
        onCleared: Popups.close()
    }

    Rectangle {
        id: card
        width: parent.width
        height: body.implicitHeight + 32
        radius: 24
        color: Qt.alpha(Theme.surface_container, 0.9)
        border.width: 1
        border.color: Qt.alpha(Theme.outline_variant, 0.6)
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.94
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: body
            x: 16; y: 16
            width: parent.width - 32
            spacing: 12
        }
    }
}
