import QtQuick
import QtQuick.Layouts

// One page of the settings: fades and slides in while it is the current one.
ColumnLayout {
    id: page
    property int idx: 0
    property int current: 0
    property string title: ""
    readonly property bool on: idx === current
    width: parent.width; spacing: 10
    opacity: on ? 1 : 0; visible: opacity > 0.01
    y: on ? -(parent && parent.scroll !== undefined ? parent.scroll : 0) : 20   // the pages container scrolls the current page
    Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Text { textFormat: Text.PlainText; text: page.title; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 18; font.bold: true; Layout.bottomMargin: 4 }
}
