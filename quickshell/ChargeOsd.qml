import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Plug-in / unplug animation: a ring fills up to the battery level, a bolt flashes in the middle and
// ripples run outwards. Plugging in uses the accent colour, unplugging the second colour and no bolt flash.
Scope {
    id: root
    property bool charging: true
    property real pct: 0
    property bool shown: false

    function play(plugged) {
        const d = UPower.displayDevice
        pct = d ? (d.percentage > 1 ? d.percentage : d.percentage * 100) : 0
        charging = plugged
        hideTimer.stop(); outAnim.stop()
        intro = 0; fill = 0; shownPct = 0; flash = 0; ripple = 0
        shown = true
        inAnim.restart(); hideTimer.restart()
    }

    property real intro: 0       // card pop
    property real fill: 0        // ring sweep 0..1 of the battery level
    property real shownPct: 0    // number counting up
    property real flash: 0       // bolt flash
    property real ripple: 0      // 0..1 for the outgoing rings
    ParallelAnimation {
        id: inAnim
        NumberAnimation { target: root; property: "intro"; from: 0; to: 1; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        SequentialAnimation {
            PauseAnimation { duration: 180 }
            ParallelAnimation {
                NumberAnimation { target: root; property: "fill"; from: 0; to: 1; duration: 1000; easing.type: Easing.OutCubic }
                NumberAnimation { target: root; property: "shownPct"; from: 0; to: root.pct; duration: 1000; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 140 }
            NumberAnimation { target: root; property: "flash"; from: 0; to: 1; duration: 220; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "flash"; to: 0.35; duration: 520; easing.type: Easing.OutCubic }
        }
        NumberAnimation { target: root; property: "ripple"; from: 0; to: 1; duration: 1500; easing.type: Easing.OutCubic }
    }
    Timer { id: hideTimer; interval: 2600; onTriggered: outAnim.start() }
    SequentialAnimation {
        id: outAnim
        NumberAnimation { target: root; property: "intro"; to: 0; duration: 320; easing.type: Easing.InBack; easing.overshoot: 1.2 }
        ScriptAction { script: root.shown = false }
    }

    // Skip the value changes while the shell starts.
    property bool ready: false
    Timer { interval: 2000; running: true; onTriggered: root.ready = true }
    Connections {
        target: UPower
        function onOnBatteryChanged() { if (root.ready) root.play(!UPower.onBattery) }
    }

    PanelWindow {
        id: win
        screen: Quickshell.screens[0]
        visible: root.shown
        anchors { bottom: true }
        margins.bottom: 110
        implicitWidth: 340; implicitHeight: 300
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-panel"

        readonly property color tone: root.charging ? Theme.accent : Theme.accent2

        // outgoing ripples
        Repeater {
            model: 3
            delegate: Rectangle {
                required property int index
                readonly property real p: Math.max(0, Math.min(1, root.ripple * 1.5 - index * 0.28))
                anchors.centerIn: ring
                width: 190 + 150 * p; height: width; radius: width / 2
                color: "transparent"; border.width: 2; border.color: win.tone
                opacity: 0.55 * (1 - p) * (root.charging ? 1 : 0.6)
            }
        }

        Item {
            id: ring
            anchors.centerIn: parent
            width: 190; height: 190
            scale: 0.6 + 0.4 * root.intro
            opacity: Math.min(1, root.intro * 1.8)

            Rectangle { anchors.fill: parent; radius: width / 2; color: Qt.alpha(Theme.panelBg, 0.96) }
            Gauge { anchors.fill: parent; value: root.fill * root.pct / 100; thickness: 12; color: win.tone; trackColor: Theme.cardHigh }
            // glow behind the bolt
            Rectangle { anchors.centerIn: parent; width: 96; height: width; radius: width / 2; color: win.tone
                        opacity: 0.16 + 0.34 * root.flash * (root.charging ? 1 : 0.3); scale: 0.8 + 0.5 * root.flash }
            ColumnLayout {
                anchors.centerIn: parent; spacing: 0
                Icon { Layout.alignment: Qt.AlignHCenter; name: root.charging ? "bolt" : "power_off"; size: 46; fill: 1
                       color: win.tone; scale: 1 + 0.25 * root.flash
                       rotation: root.charging ? 0 : -12 * (1 - root.intro) }
                Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: Math.round(root.shownPct) + "%"
                       color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 26; font.bold: true }
            }
        }
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: ring.bottom; topMargin: 14 }
            opacity: Math.min(1, root.intro * 1.4)
            textFormat: Text.PlainText
            text: root.charging ? "CHARGING" : "ON BATTERY"
            color: win.tone; font.family: Theme.mono; font.pixelSize: 13; font.bold: true
            font.letterSpacing: 3
        }
    }
}
