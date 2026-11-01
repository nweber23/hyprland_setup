import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Clipboard history (text and pictures). Type to filter, Up/Down to choose, Enter copies the entry back, Delete removes it,
// the pin keeps an entry for good (pinned texts are also snippets: `;name` in the launcher).
PanelWindow {
    id: win
    property string screenName: ""
    readonly property bool shown: Popups.current === "clipboard" && Popups.screenName === screenName
    readonly property string file: Quickshell.env("HOME") + "/.local/share/clipboard/history.json"

    property var all: []          // [{ t | img, ts, pin }] as stored by clip-store
    property var results: []
    readonly property string imageDir: Quickshell.env("HOME") + "/.local/share/clipboard/images/"
    function isText(e) { return e.t !== undefined }
    function imagePath(e) { return /^[0-9a-f]{16}\.png$/.test(e.img) ? imageDir + e.img : "" }   // only names clip-store makes
    function same(a, b) { return a.t !== undefined ? a.t === b.t : a.img === b.img }
    function refresh() {
        const q = input.text.trim().toLowerCase()
        // pinned first; a search looks at texts only
        const pool = all.filter(e => q === "" || (isText(e) && e.t.toLowerCase().includes(q)))
        results = pool.filter(e => e.pin).concat(pool.filter(e => !e.pin)).slice(0, 60)
        list.currentIndex = 0
    }
    function copy(e) {
        if (isText(e)) {
            // text goes in as an argument, never into the shell string
            Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", e.t])
        } else if (imagePath(e) !== "") {
            Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", imagePath(e)])
        }
        Popups.close()
    }
    // rewrite the file from what is stored now: the file watcher reloads the list
    function edit(fn) {
        let raw = []
        try { raw = JSON.parse(store.text()) } catch (e) {}
        store.setText(JSON.stringify(fn(raw)))
    }
    function remove(e) { edit(raw => raw.filter(i => !same(i, e))) }
    function togglePin(e) { edit(raw => raw.map(i => same(i, e) ? Object.assign({}, i, { pin: !i.pin }) : i)) }

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
        onLoaded: { try { win.all = JSON.parse(text()).filter(i => i && (typeof i.t === "string" || typeof i.img === "string")) } catch (e) { win.all = [] } win.refresh() }
    }
    onShownChanged: if (shown) { input.text = ""; store.reload(); refresh(); input.forceActiveFocus() }

    Rectangle {
        id: card
        width: parent.width
        height: col.implicitHeight + 28
        radius: 24
        color: Qt.alpha(Theme.surface_container, 0.96)
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
                implicitHeight: Math.min(contentHeight, 340)
                clip: true
                model: win.results
                highlightMoveDuration: 120
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool isImage: modelData.img !== undefined
                    width: ListView.view.width; height: isImage ? 96 : 46; radius: 16
                    color: ListView.isCurrentItem ? Theme.primary_container : (hover.containsMouse ? Theme.surface_container_high : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 10; topMargin: row.isImage ? 8 : 0; bottomMargin: row.isImage ? 8 : 0 }
                        spacing: 10
                        Image {   // pictures: a thumbnail
                            visible: row.isImage
                            Layout.preferredWidth: 110; Layout.fillHeight: true
                            fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize: Qt.size(220, 160)
                            source: row.isImage && win.imagePath(row.modelData) !== "" ? "file://" + win.imagePath(row.modelData) : ""
                        }
                        Text {
                            Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                            maximumLineCount: 1
                            text: row.isImage ? "Picture" : row.modelData.t.replace(/\s+/g, " ").trim()   // one line preview
                            color: ListView.isCurrentItem ? Theme.on_primary_container : Theme.on_surface
                            font.family: "JetBrains Mono"; font.pixelSize: 12
                        }
                        Icon { name: "push_pin"; size: 18; fill: row.modelData.pin ? 1 : 0
                               color: row.modelData.pin ? Theme.accent : Theme.on_surface_variant
                               opacity: row.modelData.pin || hover.containsMouse ? 1 : 0
                               MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: win.togglePin(row.modelData) } }
                        Icon { name: "close"; size: 18; color: Theme.on_surface_variant; opacity: hover.containsMouse ? 1 : 0
                               MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: win.remove(row.modelData) } }
                    }
                    MouseArea {
                        id: hover
                        anchors.fill: parent; hoverEnabled: true; z: -1
                        onEntered: list.currentIndex = index
                        onClicked: win.copy(row.modelData)
                    }
                }
            }
            Text { visible: win.results.length === 0; textFormat: Text.PlainText
                   text: win.all.length === 0 ? "Nothing copied yet" : "No matches"
                   color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 12 }
        }
    }
}
