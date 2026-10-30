import QtQuick
import QtQuick.Layouts

// Round node of the radial network view: soft breathing halo, filled disc, icon, name and status.
Item {
    id: n
    property color tone: Theme.accent
    property string icon: "devices"
    property string title: ""
    property string status: ""
    property bool online: true
    property bool shown: false
    implicitWidth: 220; implicitHeight: 220

    property real pulse: 1
    SequentialAnimation on pulse {
        running: n.shown; loops: Animation.Infinite
        NumberAnimation { to: 1.05; duration: 1900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 1900; easing.type: Easing.InOutSine }
    }
    // pops in when the view appears
    property real appear: 0
    onShownChanged: if (shown) popIn.restart(); else appear = 0
    Component.onCompleted: if (shown) popIn.restart()   // created while already open
    NumberAnimation { id: popIn; target: n; property: "appear"; from: 0; to: 1; duration: 650; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
    opacity: Math.min(1, appear * 1.6)
    scale: 0.6 + 0.4 * appear

    Rectangle { anchors.centerIn: parent; width: 214; height: width; radius: width / 2; scale: n.pulse
                color: Qt.alpha(n.online ? n.tone : Theme.cardHigh, 0.20)
                Behavior on color { ColorAnimation { duration: 400 } } }
    Rectangle {
        anchors.centerIn: parent; width: 152; height: width; radius: width / 2
        color: n.online ? n.tone : Theme.card
        border.width: n.online ? 0 : 2; border.color: Theme.cardHigh
        Behavior on color { ColorAnimation { duration: 400 } }
        ColumnLayout {
            anchors.centerIn: parent; spacing: 3; width: parent.width - 28
            Icon { Layout.alignment: Qt.AlignHCenter; name: n.icon; size: 32; color: n.online ? Theme.panelBg : Theme.on_surface_variant }
            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; textFormat: Text.PlainText; text: n.title
                   color: n.online ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12; font.bold: true }
            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; textFormat: Text.PlainText; text: n.status
                   color: n.online ? Qt.alpha(Theme.panelBg, 0.8) : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
        }
    }
}
