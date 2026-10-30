import QtQuick
import QtQuick.Layouts

// Item inside a BarGroup. With `fillColor` it is a coloured chip (Wi-Fi, Bluetooth, volume in the video).
Rectangle {
    id: root
    default property alias content: row.data
    property color fillColor: "transparent"
    property bool active: false          // e.g. its panel is open
    signal clicked(var mouse)
    signal scrolled(var wheel)
    Layout.fillHeight: true
    Layout.topMargin: 3; Layout.bottomMargin: 3
    implicitWidth: row.implicitWidth + 16
    radius: 8
    color: fillColor !== "transparent" ? fillColor : (active ? Theme.cardHigh : area.containsMouse ? Theme.card : "transparent")
    Behavior on color { ColorAnimation { duration: 150 } }
    RowLayout { id: row; anchors.centerIn: parent; spacing: 6 }
    MouseArea {
        id: area; anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }
}
