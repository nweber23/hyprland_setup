import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
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
    property bool centered: false           // true: centre on the screen instead of hanging under the chip
    property real pad: 20
    default property alias content: body.data
    readonly property bool shown: Popups.current === name && Popups.screenName === screenName

    visible: shown || card.opacity > 0.01
    anchors { top: true; left: true }
    margins {
        top: 8 + 34 + 8
        left: centered ? (screenWidth - panelWidth) / 2
                       : Math.max(12, Math.min(screenWidth - panelWidth - 12, Popups.anchorX - panelWidth / 2))
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

    ClippingRectangle {
        id: card
        width: parent.width
        height: body.implicitHeight + win.pad * 2
        radius: Theme.radius
        color: Theme.panelBg
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.96
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Decor {}

        ColumnLayout {
            id: body
            x: win.pad; y: win.pad
            width: parent.width - win.pad * 2
            spacing: 12
        }
    }
}
