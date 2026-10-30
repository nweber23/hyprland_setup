import QtQuick
import QtQuick.Layouts

// One section of a panel that eases in after the card, like the staggered intro of the original:
//   Reveal { p: root; index: 2; dy: 10; back: true; ...content... }
// Sections with a higher index start later (step ms apart). On close they leave quickly in reverse order.
ColumnLayout {
    id: r
    property var p                  // the Panel this section belongs to
    property int index: 0
    property real step: 70          // delay between sections in ms
    property real base: 300         // first section starts while the card is still growing
    property real dx: 0             // slide-in offset in px
    property real dy: 10
    property bool back: false       // slight overshoot (OutBack), used for covers, controls and preset buttons
    property int easing_: Easing.OutQuart
    property int duration_: 760
    property real progress: 0
    Layout.fillWidth: true
    spacing: 8
    opacity: Math.max(0, Math.min(1, progress))
    transform: Translate { x: r.dx * (1 - r.progress); y: r.dy * (1 - r.progress) }

    readonly property bool open: p ? p.shown : false
    onOpenChanged: if (open) { outAnim.stop(); inAnim.restart() } else { inAnim.stop(); outAnim.restart() }

    Component.onCompleted: if (open) inAnim.restart()   // created while the panel is already open

    SequentialAnimation {
        id: inAnim
        PauseAnimation { duration: r.base + r.index * r.step }
        NumberAnimation { target: r; property: "progress"; to: 1; duration: r.duration_
                          easing.type: r.back ? Easing.OutBack : r.easing_; easing.overshoot: 0.9 }
    }
    SequentialAnimation {
        id: outAnim
        PauseAnimation { duration: Math.max(0, 8 - r.index) * 12 }
        NumberAnimation { target: r; property: "progress"; to: 0; duration: 150; easing.type: r.back ? Easing.InBack : Easing.InCubic }
    }
}
