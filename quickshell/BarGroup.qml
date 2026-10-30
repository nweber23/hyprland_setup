import QtQuick
import QtQuick.Layouts

// Dark rounded group of bar items.
Rectangle {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing
    property int padding: 4
    signal clicked(var mouse)
    signal scrolled(var wheel)
    implicitHeight: 32
    implicitWidth: row.implicitWidth + padding * 2
    radius: 10
    color: Qt.alpha(Theme.panelBg, 0.9)
    RowLayout {
        id: row
        anchors { fill: parent; leftMargin: root.padding; rightMargin: root.padding }
        spacing: 4
    }
    MouseArea {
        z: -1; anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }
}
