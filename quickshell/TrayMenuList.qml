import Quickshell
import QtQuick
import QtQuick.Layouts

// The entries of one tray menu level. Entries with children expand in place (accordion), recursively.
ColumnLayout {
    id: root
    property var handle            // QsMenuHandle (a tray item's menu, or an entry with children)
    property int depth: 0
    signal picked()                // an entry was triggered: the owner closes the menu
    spacing: 2

    QsMenuOpener { id: opener; menu: root.handle }

    Repeater {
        model: opener.children
        delegate: ColumnLayout {
            id: entry
            required property var modelData
            property bool expanded: false
            Layout.fillWidth: true
            spacing: 2

            Rectangle {      // separator
                visible: entry.modelData.isSeparator
                Layout.fillWidth: true; Layout.topMargin: 3; Layout.bottomMargin: 3; height: 1; color: Theme.cardHigh
            }
            Rectangle {
                visible: !entry.modelData.isSeparator
                Layout.fillWidth: true; implicitHeight: 34; radius: 9
                color: area.containsMouse && entry.modelData.enabled ? Theme.cardHigh : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                RowLayout {
                    anchors { fill: parent; leftMargin: 10 + root.depth * 12; rightMargin: 10 }
                    spacing: 9
                    // check / radio state, or the entry's own icon
                    Icon { visible: entry.modelData.buttonType !== QsMenuButtonType.None && entry.modelData.checkState === Qt.Checked
                           name: entry.modelData.buttonType === QsMenuButtonType.RadioButton ? "radio_button_checked" : "check"; size: 16; color: Theme.accent }
                    Item { visible: entry.modelData.buttonType !== QsMenuButtonType.None && entry.modelData.checkState !== Qt.Checked; implicitWidth: 16 }
                    Image {
                        visible: entry.modelData.icon !== "" && entry.modelData.buttonType === QsMenuButtonType.None
                        Layout.preferredWidth: 16; Layout.preferredHeight: 16; sourceSize: Qt.size(32, 32); asynchronous: true
                        source: entry.modelData.icon.startsWith("/") || entry.modelData.icon.startsWith("image:") || entry.modelData.icon.startsWith("file:")
                                ? entry.modelData.icon : Quickshell.iconPath(entry.modelData.icon, true)
                    }
                    Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                           text: entry.modelData.text; color: entry.modelData.enabled ? Theme.on_surface : Theme.outline
                           font.family: Theme.mono; font.pixelSize: 12 }
                    Icon { visible: entry.modelData.hasChildren; name: "chevron_right"; size: 18; color: Theme.on_surface_variant
                           rotation: entry.expanded ? 90 : 0; Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } }
                }
                MouseArea {
                    id: area; anchors.fill: parent; hoverEnabled: true; enabled: entry.modelData.enabled
                    onClicked: {
                        if (entry.modelData.hasChildren) entry.expanded = !entry.expanded
                        else { entry.modelData.triggered(); root.picked() }
                    }
                }
            }
            Loader {
                Layout.fillWidth: true
                active: entry.expanded
                visible: active
                source: "TrayMenuList.qml"
                onLoaded: { item.handle = entry.modelData; item.depth = root.depth + 1; item.picked.connect(root.picked) }
            }
        }
    }
}
