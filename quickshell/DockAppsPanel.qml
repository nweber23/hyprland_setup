import Quickshell
import QtQuick
import QtQuick.Layouts

// Edit the app dock: reorder, remove, add any installed app. Opens from the "+" in the dock or with a right click on it.
Panel {
    id: root
    name: "dockapps"
    backdrop: "Dots"
    panelWidth: 460

    property string query: ""
    function save(list) { Settings.set("dockApps", list) }
    function move(i, d) {
        const l = Settings.dockApps.slice(), j = i + d
        if (j < 0 || j >= l.length) return
        const t = l[i]; l[i] = l[j]; l[j] = t
        save(l)
    }
    function remove(i) { const l = Settings.dockApps.slice(); l.splice(i, 1); save(l) }
    function add(e) {
        if (Settings.dockApps.some(a => a.id === e.id)) return
        save(Settings.dockApps.concat([{ name: e.name, id: e.id, cls: e.startupClass !== "" ? e.startupClass : e.id, icon: e.icon !== "" ? e.icon : e.id }]))
    }
    readonly property var apps: {
        const q = query.toLowerCase()
        return DesktopEntries.applications.values.filter(e => !e.noDisplay && (q === "" || e.name.toLowerCase().indexOf(q) >= 0))
                   .sort((a, b) => a.name.localeCompare(b.name)).slice(0, 60)
    }

    Reveal {
        p: root; index: 0; dy: 8
        RowLayout {
            Layout.fillWidth: true
            Icon { name: "dock_to_bottom"; size: 22; color: Theme.accent }
            Text { textFormat: Text.PlainText; text: "Dock"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 16; font.bold: true }
            Item { Layout.fillWidth: true }
            Text { textFormat: Text.PlainText; text: Settings.dockApps.length + " apps"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
        }
    }
    Reveal {
        p: root; index: 1; dy: 10
        Repeater {
            model: Settings.dockApps
            delegate: Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true; implicitHeight: 44; radius: 11; color: Theme.card
                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                    spacing: 10
                    Image { Layout.preferredWidth: 28; Layout.preferredHeight: 28; sourceSize: Qt.size(56, 56)
                            source: modelData.icon.indexOf("/") === 0 ? "file://" + modelData.icon : Quickshell.iconPath(modelData.icon, "application-x-executable") }
                    Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: modelData.name
                           color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12 }
                    Repeater {
                        model: [{ i: "arrow_upward", d: -1 }, { i: "arrow_downward", d: 1 }, { i: "close", d: 0 }]
                        delegate: Rectangle {
                            required property var modelData
                            implicitWidth: 30; implicitHeight: 30; radius: 15
                            color: bm.containsMouse ? (modelData.d === 0 ? Theme.error : Theme.cardHigh) : "transparent"
                            Icon { anchors.centerIn: parent; name: modelData.i; size: 18; color: Theme.on_surface }
                            MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true
                                        onClicked: modelData.d === 0 ? root.remove(index) : root.move(index, modelData.d) }
                        }
                    }
                }
            }
        }
    }
    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardHigh }
    Reveal {
        p: root; index: 2; dy: 10
        Text { textFormat: Text.PlainText; text: "Add an app"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 14; font.bold: true }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 38; radius: 11; color: Theme.card
            TextInput {
                id: search
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12
                onTextChanged: root.query = text
                Text { visible: search.text === ""; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText
                       text: "Search installed apps"; color: Theme.outline; font: search.font }
            }
        }
        ListView {
            Layout.fillWidth: true; Layout.preferredHeight: 240
            clip: true; spacing: 3; boundsBehavior: Flickable.StopAtBounds
            model: root.apps
            delegate: Rectangle {
                required property var modelData
                readonly property bool inDock: Settings.dockApps.some(a => a.id === modelData.id)
                width: ListView.view.width; height: 38; radius: 9
                color: am.containsMouse && !inDock ? Theme.cardHigh : "transparent"
                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    spacing: 10
                    Image { Layout.preferredWidth: 24; Layout.preferredHeight: 24; sourceSize: Qt.size(48, 48)
                            source: modelData.icon.indexOf("/") === 0 ? "file://" + modelData.icon : Quickshell.iconPath(modelData.icon, "application-x-executable") }
                    Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: modelData.name
                           color: inDock ? Theme.outline : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12 }
                    Icon { name: inDock ? "check" : "add"; size: 18; color: inDock ? Theme.outline : Theme.accent }
                }
                MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: if (!parent.inDock) root.add(modelData) }
            }
        }
    }
}
