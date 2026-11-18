import QtQuick

// Round icon button for the tools panel.
Rectangle {
    id: b
    property string icon: ""
    property bool accent: false
    signal clicked()
    implicitWidth: 52; implicitHeight: 52; radius: 26
    color: accent ? Theme.accent : (ma.containsMouse ? Theme.cardHigh : Theme.card)
    scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.07 : 1)
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    readonly property color fg: accent ? Theme.panelBg : Theme.on_surface
    readonly property bool isPlay: icon === "play_arrow" || icon === "pause"
    PlayIcon { visible: b.isPlay; anchors.centerIn: parent; size: 26; playing: b.icon === "pause"; color: b.fg }
    Icon { visible: !b.isPlay; anchors.centerIn: parent; name: b.icon; size: 26; fill: 1; color: b.fg }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: b.clicked() }
}
