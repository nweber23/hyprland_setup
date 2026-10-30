import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// Popup card that hangs under the bar. Content goes in as children (a ColumnLayout).
// Closes when the user clicks anywhere else.
//
// Opening, as in the original (read off the video, 10 frames/s):
//   0.00 s  a small translucent box appears at the anchor
//   0.05-0.5 s  it grows to full size while darkening to the panel colour
//   0.3 s+  the sections fade in one after the other (Reveal)
//   0.4-1.3 s  a thin accent outline draws itself around the card and stays
// Closing is quick: content and card fade out together.
PanelWindow {
    id: win
    required property string name
    // Plain values from the owner. Reading `screen` here would loop: shown -> visible -> screen -> shown.
    property string screenName: ""
    property real screenWidth: 1920
    property real panelWidth: 380
    property bool centered: false           // true: centre on the screen instead of hanging under the chip
    property real pad: 20
    property bool animateHeight: true       // false when the content animates its own height
    default property alias content: body.data
    readonly property bool shown: Popups.current === name && Popups.screenName === screenName

    // ---- timeline ----
    property real intro: 0      // card opacity
    property real grow: 0       // size of the card, 0 = small box, 1 = full
    property real draw: 0       // how much of the outline is drawn
    ParallelAnimation {
        id: inAnim
        NumberAnimation { target: win; property: "intro"; to: 1; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: win; property: "grow"; to: 1; duration: 620; easing.type: Easing.OutQuart }
        SequentialAnimation {
            PauseAnimation { duration: 420 }
            NumberAnimation { target: win; property: "draw"; to: 1; duration: 900; easing.type: Easing.InOutCubic }
        }
    }
    SequentialAnimation {
        id: outAnim
        PauseAnimation { duration: 60 }
        ParallelAnimation {
            NumberAnimation { target: win; property: "intro"; to: 0; duration: 190; easing.type: Easing.InQuart }
            NumberAnimation { target: win; property: "grow"; to: 0.9; duration: 190; easing.type: Easing.InQuart }
            NumberAnimation { target: win; property: "draw"; to: 0; duration: 160; easing.type: Easing.InCubic }
        }
        ScriptAction { script: win.grow = 0 }
    }
    onShownChanged: if (shown) { outAnim.stop(); inAnim.restart() } else { inAnim.stop(); outAnim.restart() }

    // content height, eased so a panel that gains rows does not jump
    readonly property real fullH: body.implicitHeight + pad * 2
    property real smoothH: fullH
    Behavior on smoothH { enabled: win.animateHeight; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    visible: shown || intro > 0.004
    anchors { top: true; left: true }
    margins {
        top: 8 + 34 + 8
        left: centered ? (screenWidth - panelWidth) / 2
                       : Math.max(12, Math.min(screenWidth - panelWidth - 12, Popups.anchorX - panelWidth / 2))
    }
    implicitWidth: panelWidth
    implicitHeight: smoothH
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
        // grows from a small box at the top centre; the content stays at full size and is clipped
        width: win.width * (0.14 + 0.86 * win.grow)
        height: win.smoothH * (0.08 + 0.92 * win.grow)
        x: (win.width - width) / 2
        radius: Theme.radius
        // starts as a translucent grey box and darkens to the panel colour while growing
        color: Qt.tint(Theme.panelBg, Qt.alpha(Theme.on_surface, 0.30 * (1 - Math.min(1, win.grow * 1.6))))
        opacity: win.intro

        Item {
            id: wrapper
            width: win.width; height: win.smoothH
            x: (card.width - width) / 2
            Decor { shown: win.shown }
            ColumnLayout {
                id: body
                x: win.pad; y: win.pad
                width: parent.width - win.pad * 2
                spacing: 12
            }
        }

        // outline that draws itself around the card (dash length grows with `draw`)
        Shape {
            anchors.fill: parent
            visible: win.draw > 0.01
            layer.enabled: true; layer.samples: 4
            ShapePath {
                readonly property real perim: 2 * (card.width + card.height) - (8 - 2 * Math.PI) * Theme.radius
                strokeColor: Qt.alpha(Theme.accent2, 0.6)
                strokeWidth: 1.5
                fillColor: "transparent"
                strokeStyle: ShapePath.DashLine
                dashPattern: [Math.max(0.01, perim * win.draw / strokeWidth), perim / strokeWidth]
                PathRectangle {
                    x: 0.75; y: 0.75; width: card.width - 1.5; height: card.height - 1.5
                    topLeftRadius: Theme.radius; topRightRadius: Theme.radius
                    bottomLeftRadius: Theme.radius; bottomRightRadius: Theme.radius
                }
            }
        }
    }
}
