import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Clipboard history (text). Type to filter, Up/Down to choose, Enter copies the entry back, Delete removes it.
PanelWindow {
    id: win
    property string screenName: ""
    readonly property bool shown: Popups.current === "clipboard" && Popups.screenName === screenName
    readonly property string file: Quickshell.env("HOME") + "/.local/share/clipboard/history.json"

    property var all: []
    property var results: []
    function refresh() {
        const q = input.text.trim().toLowerCase()
        results = (q === "" ? all : all.filter(t => t.toLowerCase().includes(q))).slice(0, 50)
        list.currentIndex = 0
    }
    function copy(text) {
        // text goes in as an argument, never into the shell string
        Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", text])
        Popups.close()
    }
    function remove(text) {
        all = all.filter(t => t !== text)
        store.setText(JSON.stringify(all))
        refresh()
    }

    visible: shown || card.opacity > 0.01
    anchors { top: true }
    margins.top: 120
    implicitWidth: 620
    implicitHeight: card.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-panel"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    HyprlandFocusGrab { windows: [win]; active: win.shown; onCleared: Popups.close() }

    FileView {
        id: store
        path: win.file
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { win.all = JSON.parse(text()) } catch (e) { win.all = [] } win.refresh() }
    }
    onShownChanged: if (shown) { input.text = ""; store.reload(); refresh(); input.forceActiveFocus() }

    Rectangle {
        id: card
        width: parent.width
        height: col.implicitHeight + 28
        radius: 24
        color: Qt.alpha(Theme.surface_container, 0.92)
        border.width: 1; border.color: Qt.alpha(Theme.outline_variant, 0.6)
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.95
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: col
            x: 14; y: 14; width: parent.width - 28; spacing: 10

            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Icon { name: "content_paste"; size: 22; color: Theme.on_surface_variant }
                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Theme.on_surface; selectionColor: Theme.primary
                    font.family: "JetBrains Mono"; font.pixelSize: 16
                    clip: true
                    onTextChanged: win.refresh()
                    Keys.onEscapePressed: Popups.close()
                    Keys.onReturnPressed: if (win.results[list.currentIndex] !== undefined) win.copy(win.results[list.currentIndex])
                    Keys.onEnterPressed: if (win.results[list.currentIndex] !== undefined) win.copy(win.results[list.currentIndex])
                    Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
                    Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
                    Keys.onDeletePressed: event => { if (input.text === "" && win.results[list.currentIndex] !== undefined) win.remove(win.results[list.currentIndex]); else event.accepted = false }
                    Text { visible: input.text === ""; textFormat: Text.PlainText; text: "Search clipboard history…"; color: Theme.outline; font: input.font }
                }
                Text { textFormat: Text.PlainText; text: win.all.length + " items"; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 10 }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: Math.min(count, 7) * 46
                clip: true
                model: win.results
                highlightMoveDuration: 120
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    width: ListView.view.width; height: 46; radius: 16
                    color: ListView.isCurrentItem ? Theme.primary_container : (hover.containsMouse ? Theme.surface_container_high : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
                        spacing: 10
                        Text {
                            Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                            maximumLineCount: 1
                            text: modelData.replace(/\s+/g, " ").trim()   // one line preview
                            color: ListView.isCurrentItem ? Theme.on_primary_container : Theme.on_surface
                            font.family: "JetBrains Mono"; font.pixelSize: 12
                        }
                        Icon { name: "close"; size: 18; color: Theme.on_surface_variant; opacity: hover.containsMouse ? 1 : 0
                               MouseArea { anchors.fill: parent; onClicked: win.remove(modelData) } }
                    }
                    MouseArea {
                        id: hover
                        anchors.fill: parent; hoverEnabled: true; z: -1
                        onEntered: list.currentIndex = index
                        onClicked: win.copy(modelData)
                    }
                }
            }
            Text { visible: win.results.length === 0; textFormat: Text.PlainText
                   text: win.all.length === 0 ? "Nothing copied yet" : "No matches"
                   color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 12 }
        }
    }
}
