import QtQuick

// Pill switch. Does not flip itself: bind `checked` and handle toggled().
Rectangle {
    id: root
    property bool checked: false
    signal toggled()
    implicitWidth: 44; implicitHeight: 24; radius: 12
    color: checked ? Theme.primary : Theme.surface_container_high
    Behavior on color { ColorAnimation { duration: 180 } }
    Rectangle {
        x: root.checked ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 18; height: 18; radius: 9
        color: root.checked ? Theme.on_primary : Theme.outline
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
    }
    MouseArea { anchors.fill: parent; onClicked: root.toggled() }
}
