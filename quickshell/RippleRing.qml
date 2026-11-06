import QtQuick

// One expanding ring of the click effect: fire(x, y) starts it, busy tells when it is done.
Item {
    id: r
    property bool busy: false
    width: 0; height: 0
    function fire(px, py) { x = px; y = py; busy = true; anim.restart() }
    Rectangle {
        id: ring
        property real d: 8
        property real o: 0
        anchors.centerIn: parent
        width: d; height: d; radius: d / 2
        color: Qt.alpha(Theme.accent, ring.o * 0.18)
        border.width: 3; border.color: Qt.alpha(Theme.accent, ring.o)
    }
    ParallelAnimation {
        id: anim
        NumberAnimation { target: ring; property: "d"; from: 8; to: 96; duration: 540; easing.type: Easing.OutCubic }
        NumberAnimation { target: ring; property: "o"; from: 0.9; to: 0; duration: 540; easing.type: Easing.InQuad }
        onFinished: r.busy = false
    }
}
