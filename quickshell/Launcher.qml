import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// App launcher: type to filter, Up/Down to choose, Enter to start, Esc to close.
// Extras: "2+2*3" calculates (Enter copies the result), ":cat" searches emoji (Enter copies), and any text offers a web search.
PanelWindow {
    id: win
    property string screenName: ""
    readonly property bool shown: Popups.current === "launcher" && Popups.screenName === screenName
    readonly property int maxRows: 7

    visible: shown || card.opacity > 0.01
    anchors { top: true }
    margins.top: 120
    implicitWidth: 560
    implicitHeight: card.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-panel"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab { windows: [win]; active: win.shown; onCleared: Popups.close() }

    // Rank: name prefix > name contains > keywords/comment contains. Empty query lists everything by name.
    property var results: []
    property var emojis: []   // [{name, comment, icon, execute}] for the current ":" query
    function copyEntry(text, label, icon) {
        return { name: label, comment: "Enter copies it", icon: icon, execute: () => Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", text]) }
    }
    // Plain arithmetic only: the regex keeps everything but digits, operators and brackets out of eval.
    function calc(q) {
        if (!/^[0-9+\-*\/().,%^ ]+$/.test(q) || !/[+\-*\/%^]/.test(q) || !/[0-9]/.test(q)) return null
        try {
            const v = eval(q.replace(/,/g, ".").replace(/\^/g, "**"))
            return typeof v === "number" && isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : null
        } catch (e) { return null }
    }
    Process {
        id: emojiSearch
        stdout: StdioCollector { onStreamFinished: {
            win.emojis = text.split("\n").filter(l => l).map(l => { const p = l.split("\t"); return win.copyEntry(p[0], p[0] + "  " + p[1], "face-smile") })
            win.refresh()
        } }
    }
    Timer { id: emojiDelay; interval: 120; onTriggered: { emojiSearch.command = ["emoji-search"].concat(input.text.trim().slice(1).split(/\s+/).filter(w => w)); emojiSearch.running = true } }
    function refresh() {
        const raw = input.text.trim(), q = raw.toLowerCase()
        if (raw.startsWith(":") && raw.length > 1) {
            results = emojis
            list.currentIndex = 0
            return
        }
        const out = []
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; i++) {
            const a = apps[i]
            if (a.noDisplay) continue
            const n = a.name.toLowerCase()
            let score = 0
            if (q === "") score = 1
            else if (n.startsWith(q)) score = 3
            else if (n.includes(q)) score = 2
            else if ((a.genericName + " " + a.comment + " " + a.keywords.join(" ")).toLowerCase().includes(q)) score = 1
            if (score > 0) out.push({ entry: a, score: score })
        }
        out.sort((x, y) => y.score - x.score || x.entry.name.localeCompare(y.entry.name))
        let list_ = out.slice(0, 60).map(o => o.entry)
        const c = calc(raw)
        if (c !== null) list_.unshift(copyEntry(c, "= " + c, "accessories-calculator"))
        if (raw !== "")
            list_.push({ name: "Search the web for \u201c" + raw + "\u201d", comment: "DuckDuckGo", icon: "web-browser",
                         execute: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(raw)]) })
        results = list_
        list.currentIndex = 0
    }
    function launch(entry) { if (!entry) return; entry.execute(); Popups.close() }
    // Entries are scanned asynchronously; rebuild once they arrive.
    Connections { target: DesktopEntries.applications; function onValuesChanged() { if (win.shown) win.refresh() } }
    onShownChanged: if (shown) { input.text = ""; refresh(); input.forceActiveFocus() }

    Rectangle {
        id: card
        width: parent.width
        height: col.implicitHeight + 28
        radius: 24
        color: Qt.alpha(Theme.surface_container, 0.96)
        border.width: 1
        border.color: Qt.alpha(Theme.outline_variant, 0.6)
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.95
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: col
            x: 14; y: 14
            width: parent.width - 28
            spacing: 10

            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Icon { name: "search"; size: 22; color: Theme.on_surface_variant }
                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Theme.on_surface
                    font.family: "JetBrains Mono"; font.pixelSize: 16
                    selectionColor: Theme.primary
                    clip: true
                    onTextChanged: { if (text.startsWith(":")) { win.emojis = []; emojiDelay.restart() } win.refresh() }
                    Keys.onEscapePressed: Popups.close()
                    Keys.onReturnPressed: win.launch(win.results[list.currentIndex])
                    Keys.onEnterPressed: win.launch(win.results[list.currentIndex])
                    Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
                    Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
                    Text {
                        visible: input.text === ""
                        textFormat: Text.PlainText
                        text: "Search apps…"
                        color: Theme.outline
                        font: input.font
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: Math.min(count, win.maxRows) * 48
                clip: true
                model: win.results
                currentIndex: 0
                highlightMoveDuration: 120
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 48; radius: 16
                    color: ListView.isCurrentItem ? Theme.primary_container : (hover.containsMouse ? Theme.surface_container_high : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 12
                        Image {
                            Layout.preferredWidth: 28; Layout.preferredHeight: 28
                            source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                            sourceSize: Qt.size(56, 56)
                            asynchronous: true
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight
                                   text: modelData.name; font.family: "JetBrains Mono"; font.pixelSize: 13
                                   color: ListView.isCurrentItem ? Theme.on_primary_container : Theme.on_surface }
                            Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight
                                   visible: text !== ""
                                   text: modelData.comment; font.family: "JetBrains Mono"; font.pixelSize: 10
                                   color: Theme.on_surface_variant }
                        }
                    }
                    MouseArea {
                        id: hover
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: list.currentIndex = index
                        onClicked: win.launch(modelData)
                    }
                }
            }
        }
    }
}
