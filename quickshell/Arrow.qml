import QtQuick

// Small chevron button that grows on hover. Set `act` to the function to call on click.
Icon {
    id: root
    property var act
    size: 22; color: Theme.on_surface_variant
    scale: ar.containsMouse ? 1.25 : 1
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
    MouseArea { id: ar; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: root.act() }
}
