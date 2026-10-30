import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Desktop notification daemon (org.freedesktop.Notifications) with popup cards in the top-right corner.
Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        // Apps get plain text only; the cards render it with textFormat PlainText as well.
        bodyMarkupSupported: false
        onNotification: n => { n.tracked = true; NotifHistory.add(n) }
    }

    // Show on the monitor that has focus right now.
    readonly property var targetScreen: {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
    }

    PanelWindow {
        id: win
        screen: root.targetScreen
        // Always mapped, 1 px tall while empty. Binding this to the list made the window never map.
        visible: !Popups.dnd
        anchors { top: true; right: true }
        margins { top: 8 + 34 + 8; right: 12 }
        implicitWidth: 380
        implicitHeight: Math.max(1, list.contentHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "qs-panel"

        ListView {
            id: list
            anchors.fill: parent
            model: server.trackedNotifications
            spacing: 10
            interactive: false
            cacheBuffer: 4000   // build every card even while the window is still 1 px tall (its height follows contentHeight)
            add: Transition { ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; from: 60; to: 0; duration: 280; easing.type: Easing.OutCubic } } }
            remove: Transition { ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 180 }
                NumberAnimation { property: "x"; to: 60; duration: 220; easing.type: Easing.InCubic } } }
            displaced: Transition { NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic } }

            delegate: Rectangle {
                id: card
                required property var modelData   // the Notification
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                width: ListView.view.width
                height: col.implicitHeight + 28
                radius: 20
                color: Qt.alpha(Theme.surface_container, 0.96)
                border.width: critical ? 2 : 1
                border.color: critical ? Theme.error : Qt.alpha(Theme.outline_variant, 0.6)

                // Auto-dismiss: the app's timeout, else 6 s. Critical ones stay until closed. Hovering pauses.
                Timer {
                    interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout * 1000 : 6000
                    running: !card.critical && !hover.containsMouse
                    onTriggered: card.modelData.expire()
                }
                MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; onClicked: card.modelData.dismiss() }

                RowLayout {
                    id: col
                    x: 14; y: 14
                    width: parent.width - 28
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 44; Layout.alignment: Qt.AlignTop
                        Image {
                            id: iconImage
                            anchors.fill: parent
                            visible: status === Image.Ready
                            source: card.modelData.image !== "" ? card.modelData.image
                                  : card.modelData.appIcon !== "" ? Quickshell.iconPath(card.modelData.appIcon, true) : ""
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(88, 88)
                            asynchronous: true
                        }
                        Icon { anchors.centerIn: parent; name: "notifications"; size: 28; color: Theme.on_surface_variant
                               visible: iconImage.status !== Image.Ready }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight
                               text: card.modelData.appName; color: Theme.on_surface_variant
                               font.family: "JetBrains Mono"; font.pixelSize: 10 }
                        Text { textFormat: Text.PlainText; Layout.fillWidth: true; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                               text: card.modelData.summary; color: Theme.on_surface
                               font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
                        Text { textFormat: Text.PlainText; Layout.fillWidth: true; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                               visible: text !== ""
                               text: card.modelData.body; color: Theme.on_surface_variant
                               font.family: "JetBrains Mono"; font.pixelSize: 11 }
                        RowLayout {
                            Layout.topMargin: 4; spacing: 6
                            visible: card.modelData.actions.length > 0
                            Repeater {
                                model: card.modelData.actions
                                delegate: Rectangle {
                                    required property var modelData
                                    implicitHeight: 26; implicitWidth: lbl.implicitWidth + 20; radius: 13
                                    color: Theme.primary_container
                                    Text { id: lbl; anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData.text
                                           color: Theme.on_primary_container; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                    MouseArea { anchors.fill: parent; onClicked: modelData.invoke() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
