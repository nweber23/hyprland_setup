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

    // Intro timeline (as in the original): the card eases in over 760 ms, sections follow via Reveal;
    // closing is quick and runs backwards.
    property real intro: 0
    NumberAnimation { id: introAnim; target: win; property: "intro"; to: 1; duration: 760; easing.type: Easing.OutQuart }
    SequentialAnimation {
        id: outAnim
        PauseAnimation { duration: 70 }
        NumberAnimation { target: win; property: "intro"; to: 0; duration: 170; easing.type: Easing.InQuart }
    }
    onShownChanged: if (shown) { outAnim.stop(); introAnim.restart() } else { introAnim.stop(); outAnim.restart() }

    visible: shown || intro > 0.004
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
        opacity: win.intro
        scale: 0.92 + 0.08 * win.intro
        transformOrigin: Item.Top
        transform: Translate { y: 12 * (1 - win.intro) }
        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Decor {}

        ColumnLayout {
            id: body
            x: win.pad; y: win.pad
            width: parent.width - win.pad * 2
            spacing: 12
        }
    }
}
