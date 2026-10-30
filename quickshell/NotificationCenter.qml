import Quickshell
import QtQuick
import QtQuick.Layouts

// Notification history with Do-not-disturb and Clear.
Panel {
    id: root
    name: "notifications"
    panelWidth: 420
    centered: false
    fixedH: 560       // the list grows and shrinks; the window keeps one size
    onShownChanged: if (shown) NotifHistory.markRead()

    function ago(ms, tickDate) {      // tickDate only makes the binding re-evaluate every minute
        const s = Math.floor((Date.now() - ms) / 1000)
        return s < 60 ? "now" : s < 3600 ? Math.floor(s / 60) + " min ago" : s < 86400 ? Math.floor(s / 3600) + " h ago" : Math.floor(s / 86400) + " d ago"
    }
    SystemClock { id: tick; precision: SystemClock.Minutes }

    Reveal {
        p: root; index: 0; dy: 8
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            Text { Layout.fillWidth: true; textFormat: Text.PlainText; text: "Notifications"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
            Rectangle {   // do not disturb
                implicitHeight: 30; implicitWidth: dndRow.implicitWidth + 22; radius: 10
                color: Popups.dnd ? Theme.accent : (dArea.containsMouse ? Theme.cardHigh : Theme.card)
                Behavior on color { ColorAnimation { duration: 160 } }
                RowLayout { id: dndRow; anchors.centerIn: parent; spacing: 6
                    Icon { name: Popups.dnd ? "notifications_off" : "notifications_active"; size: 16; color: Popups.dnd ? Theme.panelBg : Theme.on_surface }
                    Text { textFormat: Text.PlainText; text: "Do not disturb"; font.family: Theme.mono; font.pixelSize: 11; font.bold: true; color: Popups.dnd ? Theme.panelBg : Theme.on_surface } }
                MouseArea { id: dArea; anchors.fill: parent; hoverEnabled: true; onClicked: Popups.dnd = !Popups.dnd }
            }
            Rectangle {
                implicitHeight: 30; implicitWidth: clrTxt.implicitWidth + 22; radius: 10; opacity: NotifHistory.items.count > 0 ? 1 : 0.4
                color: cArea.containsMouse ? Theme.cardHigh : Theme.card
                Text { id: clrTxt; anchors.centerIn: parent; textFormat: Text.PlainText; text: "Clear"; font.family: Theme.mono; font.pixelSize: 11; font.bold: true; color: Theme.on_surface }
                MouseArea { id: cArea; anchors.fill: parent; hoverEnabled: true; enabled: NotifHistory.items.count > 0; onClicked: NotifHistory.clear() }
            }
        }
    }

    Reveal {
        p: root; index: 1; dy: 12
        Text { visible: NotifHistory.items.count === 0; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 24; Layout.bottomMargin: 24; textFormat: Text.PlainText
               text: "No notifications"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
        ListView {
            id: list
            visible: NotifHistory.items.count > 0
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 420)
            clip: true; spacing: 8; model: NotifHistory.items
            boundsBehavior: Flickable.StopAtBounds
            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 } }
            remove: Transition { ParallelAnimation { NumberAnimation { property: "opacity"; to: 0; duration: 180 } NumberAnimation { property: "x"; to: 60; duration: 220; easing.type: Easing.InCubic } } }
            displaced: Transition { NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic } }
            delegate: Item {
                id: slot
                required property int index
                required property string app
                required property string summary
                required property string body
                required property string icon
                required property real time
                width: ListView.view.width; height: card.implicitHeight
                NotifCard {
                    id: card
                    width: parent.width; p: root
                    row: slot.index; app: slot.app; summary: slot.summary; body: slot.body; icon: slot.icon; time: slot.time
                    ago: root.ago(slot.time, tick.date)
                    onRemoveRequested: NotifHistory.remove(slot.index)
                }
            }
        }
    }
}
