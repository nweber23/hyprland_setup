import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// App launcher: type to filter, Up/Down to choose, Enter to start, Esc to close.
// Extras: "2+2*3" calculates, "5 km in mi" and "20 usd in eur" convert, "timer 10m" starts a timer, ":cat" searches emoji,
// "f name" finds files, "r name" lists recent files (Enter opens), and any text offers a web search. Enter copies results.
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
    Process {
        id: emojiSearch
        stdout: StdioCollector { onStreamFinished: {
            win.emojis = text.split("\n").filter(l => l).map(l => { const p = l.split("\t"); return win.copyEntry(p[0], p[0] + "  " + p[1], "face-smile") })
            win.refresh()
        } }
    }
    Timer { id: emojiDelay; interval: 120; onTriggered: { emojiSearch.command = ["emoji-search"].concat(input.text.trim().slice(1).split(/\s+/).filter(w => w)); emojiSearch.running = true } }
    // ---- conversions, timer, files ----
    property string currencyText: ""      // "20 USD = 17.90 EUR" once the rate arrived
    property string currencyValue: ""
    property var fileHits: []             // for "f name"
    property var recentHits: []           // for "r name"
    function pathEntry(path) {
        const i = path.lastIndexOf("/")
        return { name: path.slice(i + 1), comment: path.slice(0, i).replace(Quickshell.env("HOME"), "~"), icon: "text-x-generic",
                 execute: () => Quickshell.execDetached(["xdg-open", path]) }
    }
    // "timer 10m", "t 90s", "timer 1.5h"
    function timerSpec(raw) {
        const m = /^(?:timer|t)\s+(\d+(?:[.,]\d+)?)\s*(s|sec|m|min|h)?$/i.exec(raw)
        if (!m) return 0
        const n = parseFloat(m[1].replace(",", ".")), u = (m[2] || "m").toLowerCase()
        return Math.round(n * (u === "h" ? 3600 : (u === "s" || u === "sec") ? 1 : 60))
    }
    Process {
        id: rate
        stdout: StdioCollector { onStreamFinished: {
            try {
                const j = JSON.parse(text), to = Object.keys(j.rates)[0]
                win.currencyValue = String(Number(j.rates[to].toFixed(2)))
                win.currencyText = j.amount + " " + j.base + " = " + win.currencyValue + " " + to
            } catch (e) { win.currencyText = "" }
            win.refresh()
        } }
    }
    Process {
        id: fileSearch
        stdout: StdioCollector { onStreamFinished: { win.fileHits = text.split("\n").filter(l => l).map(win.pathEntry); win.refresh() } }
    }
    Process {
        id: recentSearch
        stdout: StdioCollector { onStreamFinished: { win.recentHits = text.split("\n").filter(l => l).map(win.pathEntry); win.refresh() } }
    }
    Timer { id: lookupDelay; interval: 350; onTriggered: {
        const t = input.text.trim(), cv = Convert.parse(t)
        if (cv && cv.kind === "currency") {   // codes and amount were validated by Convert.parse: three letters each, a plain number
            rate.command = ["curl", "-sL", "-m", "6", "https://api.frankfurter.dev/v1/latest?amount=" + cv.amount + "&base=" + cv.from + "&symbols=" + cv.to]
            rate.running = true
        }
        const f = /^f\s+(.+)$/.exec(t)
        if (f) {   // the name goes in as an argument, never into the shell string
            fileSearch.command = ["sh", "-c", 'find "$HOME" -maxdepth 7 \\( -name ".*" -o -name node_modules -o -name snap \\) -prune -o -iname "*$1*" -print 2>/dev/null | head -40', "sh", f[1]]
            fileSearch.running = true
        }
        const r = /^r\s*(.*)$/.exec(t)
        if (r && /^r\s/.test(input.text)) { recentSearch.command = ["recent-files"].concat(r[1].split(/\s+/).filter(w => w)); recentSearch.running = true }
    } }
    function onQuery() {
        const t = input.text
        if (t.startsWith(":")) { emojis = []; emojiDelay.restart() }
        currencyText = ""
        if (/^f\s+\S/.test(t)) fileHits = []
        if (/^[a-z]{3}\s*\d|^\d/.test(t.trim()) || /^f\s+\S/.test(t) || /^r\s/.test(t)) lookupDelay.restart()
    }
    function refresh() {
        const raw = input.text.trim(), q = raw.toLowerCase()
        if (/^f\s+\S/.test(input.text)) { results = fileHits; list.currentIndex = 0; return }
        if (/^r\s/.test(input.text)) { results = recentHits; list.currentIndex = 0; return }
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
        const c = Tools.calc(raw)
        if (c !== null) list_.unshift(copyEntry(c, "= " + c, "accessories-calculator"))
        const cv = Convert.parse(raw)
        if (cv && cv.kind === "unit") list_.unshift(copyEntry(cv.value, cv.text, "accessories-calculator"))
        else if (cv && cv.kind === "currency")
            list_.unshift(currencyText !== "" ? copyEntry(currencyValue, currencyText, "accessories-calculator")
                                              : { name: "Looking up the rate\u2026", comment: "ECB rates from frankfurter.dev", icon: "accessories-calculator", execute: () => {} })
        const secs = timerSpec(raw)
        if (secs > 0) list_.unshift({ name: "Start a " + Tools.fmt(secs) + " timer", comment: "Enter starts it, it shows in the bar", icon: "alarm-clock",
                                      execute: () => { if (Tools.running) Tools.reset(); Tools.setTotal(secs); Tools.start() } })
        if (raw !== "")
            list_.push({ name: "Search the web for \u201c" + raw + "\u201d", comment: "DuckDuckGo", icon: "web-browser",
                         execute: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(raw)]) })
        results = list_
        list.currentIndex = 0
    }
    function launch(entry) { if (!entry) return; entry.execute(); Popups.close() }
    // Entries are scanned asynchronously; rebuild once they arrive.
    Connections { target: DesktopEntries.applications; function onValuesChanged() { if (win.shown) win.refresh() } }
    onShownChanged: if (shown) { input.text = Popups.launcherPrefill; Popups.launcherPrefill = ""; onQuery(); refresh(); input.forceActiveFocus() }

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
                    onTextChanged: { win.onQuery(); win.refresh() }
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
