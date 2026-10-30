import QtQuick

// Square button for the session row. Destructive ones (needsConfirm) need a second click within 3 s.
Rectangle {
    id: tile
    property string icon: ""
    property bool armed: false
    property bool needsConfirm: false
    signal activated()
    implicitHeight: 62; radius: 12
    color: area.containsMouse ? Theme.cardHigh : Theme.card
    border.width: armed ? 1 : 0; border.color: Theme.error
    scale: area.pressed ? 0.93 : (area.containsMouse ? 1.06 : 1)
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Icon { anchors.centerIn: parent; name: tile.armed ? "check" : tile.icon; size: 24; color: tile.armed ? Theme.error : Theme.on_surface }
    Timer { id: disarm; interval: 3000; onTriggered: tile.armed = false }
    MouseArea {
        id: area; anchors.fill: parent; hoverEnabled: true
        onClicked: {
            if (tile.needsConfirm && !tile.armed) { tile.armed = true; disarm.restart(); return }
            tile.armed = false; tile.activated()
        }
    }
}
