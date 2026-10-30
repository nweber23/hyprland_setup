import QtQuick
import QtQuick.Layouts

// Rounded pill that hosts a row of children and reports clicks and scrolling.
Rectangle {
    id: root
    default property alias content: row.data
    property bool highlighted: false
    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitHeight: 34
    implicitWidth: row.implicitWidth + 24
    radius: height / 2
    color: highlighted ? Theme.primary_container
         : area.containsMouse ? Qt.alpha(Theme.surface_container_high, 0.92)
         : Qt.alpha(Theme.surface_container, 0.78)
    Behavior on color { ColorAnimation { duration: 180 } }
    scale: area.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }
    MouseArea {
        id: area
        z: -1   // below the children, so buttons inside a chip get their own clicks
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }
}
