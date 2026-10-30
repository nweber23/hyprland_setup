import QtQuick
import QtQuick.Effects
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
    property bool canDisconnect: false   // hovering turns the node red; a click asks the owner to disconnect
    signal disconnectRequested()
    readonly property bool danger: canDisconnect && online && coreArea.containsMouse
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
    property real bump: 1
    SequentialAnimation { id: bumpAnim
        NumberAnimation { target: n; property: "bump"; to: 1.15; duration: 250; easing.type: Easing.OutBack }
        NumberAnimation { target: n; property: "bump"; to: 1.0; duration: 600; easing.type: Easing.OutQuint } }
    onOnlineChanged: if (appear > 0.5) bumpAnim.restart()
    opacity: Math.min(1, appear * 1.6)
    scale: (0.6 + 0.4 * appear) * bump

    Rectangle { anchors.centerIn: parent; width: 214; height: width; radius: width / 2; scale: n.pulse
                color: Qt.alpha(n.online ? n.tone : Theme.cardHigh, 0.20)
                Behavior on color { ColorAnimation { duration: 400 } } }
    // soft shadow under the disc, like the original
    Rectangle { id: disc; anchors.centerIn: parent; width: 152; height: width; radius: width / 2
        readonly property color topColor: n.danger ? Qt.tint(Qt.lighter(n.tone, 1.15), Qt.alpha(Theme.error, 0.75)) : Qt.lighter(n.tone, 1.15)
        readonly property color bottomColor: n.danger ? Qt.tint(n.tone, Qt.alpha(Theme.error, 0.75)) : n.tone
        gradient: Gradient {
            GradientStop { position: 0.0; color: n.online ? disc.topColor : Theme.card
                           Behavior on color { ColorAnimation { duration: 250 } } }
            GradientStop { position: 1.0; color: n.online ? disc.bottomColor : Theme.panelBg
                           Behavior on color { ColorAnimation { duration: 250 } } }
        }
        border.width: 2; border.color: n.online ? Qt.lighter(n.danger ? Theme.error : n.tone, 1.1) : Theme.cardHigh
        Behavior on border.color { ColorAnimation { duration: 250 } }
        layer.enabled: n.online
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#000000"; shadowOpacity: 0.5; shadowBlur: 1.0; shadowVerticalOffset: 5 }
        ColumnLayout {
            anchors.centerIn: parent; spacing: 3; width: parent.width - 28
            Icon { Layout.alignment: Qt.AlignHCenter; name: n.danger ? "link_off" : n.icon; size: 32; color: n.online ? Theme.panelBg : Theme.on_surface_variant }
            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; textFormat: Text.PlainText; text: n.title
                   color: n.online ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12; font.bold: true }
            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; textFormat: Text.PlainText
                   text: n.danger ? "Click to disconnect" : n.status
                   color: n.online ? Qt.alpha(Theme.panelBg, 0.8) : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
        }
        MouseArea { id: coreArea; anchors.fill: parent; hoverEnabled: true; enabled: n.canDisconnect && n.online
                    onClicked: n.disconnectRequested() }
    }
}
