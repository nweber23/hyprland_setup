import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Polkit authentication agent: shows the password prompt when an app asks for admin rights.
Scope {
    id: root
    PolkitAgent { id: agent }
    readonly property var flow: agent.flow

    PanelWindow {
        id: win
        screen: Quickshell.screens[0]
        visible: agent.isActive
        implicitWidth: 420; implicitHeight: card.height
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-panel"
        WlrLayershell.keyboardFocus: agent.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        onVisibleChanged: if (visible) { pwd.text = ""; pwd.forceActiveFocus() }

        Rectangle {
            id: card
            width: parent.width
            height: col.implicitHeight + 36
            radius: 24
            color: Qt.alpha(Theme.surface_container, 0.96)
            border.width: 1; border.color: Qt.alpha(Theme.outline_variant, 0.8)

            ColumnLayout {
                id: col
                x: 18; y: 18; width: parent.width - 36; spacing: 12
                RowLayout {
                    spacing: 10
                    Icon { name: "admin_panel_settings"; size: 28; color: Theme.primary }
                    Text { textFormat: Text.PlainText; text: "Authentication required"; color: Theme.on_surface
                           font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
                }
                Text { textFormat: Text.PlainText; Layout.fillWidth: true; wrapMode: Text.Wrap
                       text: root.flow ? root.flow.message : ""
                       color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 12 }
                Text { textFormat: Text.PlainText; Layout.fillWidth: true; wrapMode: Text.Wrap
                       visible: root.flow !== null && root.flow.supplementaryMessage !== ""
                       text: root.flow ? root.flow.supplementaryMessage : ""
                       color: root.flow && root.flow.supplementaryIsError ? Theme.error : Theme.on_surface_variant
                       font.family: "JetBrains Mono"; font.pixelSize: 11 }

                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 40; radius: 14
                    color: Theme.surface_container_high
                    visible: root.flow !== null && root.flow.isResponseRequired
                    TextInput {
                        id: pwd
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                        color: Theme.on_surface; selectionColor: Theme.primary
                        font.family: "JetBrains Mono"; font.pixelSize: 14
                        clip: true
                        onAccepted: if (root.flow) { root.flow.submit(pwd.text); pwd.text = "" }
                        Keys.onEscapePressed: if (root.flow) root.flow.cancelAuthenticationRequest()
                        Text { visible: pwd.text === ""; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText
                               text: root.flow ? root.flow.inputPrompt : ""; color: Theme.outline; font: pwd.font }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight; spacing: 8
                    Rectangle {
                        implicitWidth: 90; implicitHeight: 32; radius: 16; color: Theme.surface_container_high
                        Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: "Cancel"; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; onClicked: if (root.flow) root.flow.cancelAuthenticationRequest() }
                    }
                    Rectangle {
                        implicitWidth: 110; implicitHeight: 32; radius: 16; color: Theme.primary
                        Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: "Authenticate"; color: Theme.on_primary; font.family: "JetBrains Mono"; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; onClicked: if (root.flow) { root.flow.submit(pwd.text); pwd.text = "" } }
                    }
                }
            }
        }
    }
}
