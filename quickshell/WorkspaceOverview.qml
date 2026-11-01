import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Workspace overview (Super+O): the ten workspace numbers as cards, each with its windows as small previews, across all monitors.
// Click a card to go there (every monitor switches), drag a window onto another card to move it. Arrows / digits / Enter / Esc work too.
PanelWindow {
    id: win
    property string screenName: ""
    readonly property bool active: Popups.current === "workspaces"
    readonly property bool shown: active && Popups.screenName === screenName   // this screen holds the cards and the keys

    property var cards: []      // [{ n, wins: [{ address, cls, title, top, ratio }] }]
    property int sel: 0
    readonly property int cols: 5
    readonly property real cellW: Math.min(400, (width - 160) / cols)
    readonly property real cellH: cellW * 0.78

    function noPrefix(a) { return String(a).replace(/^0x/, "") }
    function refresh() { if (!listing.running) listing.running = true }
    function build(json) {
        let clients = []
        try { clients = JSON.parse(json) } catch (e) {}
        const tops = Hyprland.toplevels.values
        const groups = {}
        for (const c of clients) {
            if (!c.mapped || c.hidden || !c.address || !c.workspace || c.workspace.id <= 0) continue
            const n = (c.workspace.id - 1) % 10 + 1
            ;(groups[n] = groups[n] || []).push({ top: tops.find(t => noPrefix(t.address) === noPrefix(c.address)) ?? null,
                                                  address: c.address, cls: c.class || "", title: c.title || c.class || "",
                                                  ratio: c.size && c.size[1] > 0 ? c.size[0] / c.size[1] : 1.6 })
        }
        const out = []
        for (let n = 1; n <= 10; n++) out.push({ n: n, wins: groups[n] || [] })
        const first = cards.length === 0
        cards = out
        if (first) {
            const m = Hyprland.focusedMonitor
            const id = m && m.activeWorkspace ? m.activeWorkspace.id : 1
            sel = Math.max(0, ((id - 1) % 10 + 10) % 10)
        }
    }
    Process {
        id: listing
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector { onStreamFinished: win.build(text) }
    }
    onShownChanged: if (shown) { cards = []; refresh(); keys.forceActiveFocus() }

    function go(n) { Quickshell.execDetached(["hyprctl", "eval", "qsGotoWorkspace(" + Math.round(n) + ")"]); Popups.close() }
    function moveWindow(address, n) {
        if (!/^0x[0-9a-f]+$/.test(address)) return
        Quickshell.execDetached(["hyprctl", "eval", "qsMoveWindow(\"" + address + "\", " + Math.round(n) + ")"])
        reload.restart()
    }
    Timer { id: reload; interval: 450; onTriggered: win.refresh() }

    visible: active || scrim.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-overview"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.alpha(Theme.surface, 0.66)
        opacity: win.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: Popups.close() }
    }

    FocusScope {
        id: keys
        anchors.fill: parent
        visible: win.shown
        Keys.onPressed: event => {
            const d = event.key
            if (d === Qt.Key_Right) win.sel = Math.min(9, win.sel + 1)
            else if (d === Qt.Key_Left) win.sel = Math.max(0, win.sel - 1)
            else if (d === Qt.Key_Down) win.sel = Math.min(9, win.sel + win.cols)
            else if (d === Qt.Key_Up) win.sel = Math.max(0, win.sel - win.cols)
            else if (d === Qt.Key_Tab) win.sel = (win.sel + 1) % 10
            else if (d === Qt.Key_Backtab) win.sel = (win.sel + 9) % 10
            else if (d === Qt.Key_Return || d === Qt.Key_Enter) win.go(win.sel + 1)
            else if (d === Qt.Key_Escape) Popups.close()
            else if (d >= Qt.Key_1 && d <= Qt.Key_9) win.go(d - Qt.Key_0)
            else if (d === Qt.Key_0) win.go(10)
            else return
            event.accepted = true
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 52 }
            textFormat: Text.PlainText
            text: "Workspaces   ·   click or 1-0 to go   ·   drag a window onto a card to move it"
            color: Qt.alpha(Theme.on_surface, 0.6); font.family: Theme.mono; font.pixelSize: 12
            opacity: win.shown ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        Grid {
            id: grid
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: 14 }
            columns: win.cols; spacing: 0
            Repeater {
                model: win.cards
                delegate: Item {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property bool selected: win.sel === index
                    readonly property bool occupied: modelData.wins.length > 0
                    property bool holding: false          // a window of this card is being dragged
                    width: win.cellW; height: win.cellH
                    z: holding ? 50 : 0
                    property real reveal: 0
                    opacity: reveal
                    transform: Translate { y: 20 * (1 - card.reveal) }
                    SequentialAnimation { running: true
                        PauseAnimation { duration: card.index * 28 }
                        NumberAnimation { target: card; property: "reveal"; to: 1; duration: 360; easing.type: Easing.OutCubic } }

                    Rectangle {
                        id: body
                        anchors { fill: parent; margins: 8 }
                        radius: 18
                        color: drop.containsDrag ? Qt.alpha(Theme.accent, 0.20) : (card.occupied ? Theme.card : Qt.alpha(Theme.card, 0.55))
                        border.width: card.selected || drop.containsDrag ? 3 : 1
                        border.color: card.selected || drop.containsDrag ? Theme.accent : Qt.alpha(Theme.outline_variant, 0.7)
                        scale: card.selected ? 1.02 : 1
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: win.sel = card.index
                            onClicked: win.go(card.modelData.n)
                        }
                        DropArea {
                            id: drop
                            anchors.fill: parent; keys: ["win"]
                            onDropped: drag => win.moveWindow(drag.source.address, card.modelData.n)
                        }
                        Text { x: 14; y: 8; textFormat: Text.PlainText; text: card.modelData.n % 10
                               color: card.selected ? Theme.accent : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 20; font.bold: true }
                        Text { anchors { right: parent.right; top: parent.top; margins: 14 } textFormat: Text.PlainText
                               text: card.occupied ? card.modelData.wins.length + (card.modelData.wins.length === 1 ? " window" : " windows") : "empty"
                               color: Theme.outline; font.family: Theme.mono; font.pixelSize: 10 }
                    }

                    // previews of this workspace's windows, in a small grid under the header
                    Item {
                        id: area
                        x: 18; y: 42; width: card.width - 36; height: card.height - 60
                        readonly property int k: card.modelData.wins.length
                        readonly property int gcols: k <= 1 ? 1 : (k <= 4 ? 2 : 3)
                        readonly property int grows: Math.max(1, Math.ceil(k / gcols))
                        readonly property real cw: width / gcols
                        readonly property real ch: height / grows
                        Repeater {
                            model: card.modelData.wins
                            delegate: Item {
                                id: thumb
                                required property var modelData
                                required property int index
                                readonly property string address: modelData.address
                                readonly property real homeX: (index % area.gcols) * area.cw
                                readonly property real homeY: Math.floor(index / area.gcols) * area.ch
                                width: area.cw - 8; height: area.ch - 8
                                Binding on x { when: !dh.active; value: thumb.homeX + 4 }
                                Binding on y { when: !dh.active; value: thumb.homeY + 4 }
                                Behavior on x { enabled: !dh.active; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                Behavior on y { enabled: !dh.active; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                z: dh.active ? 100 : 1
                                scale: dh.active ? 1.06 : 1
                                Behavior on scale { NumberAnimation { duration: 160 } }
                                Drag.active: dh.active
                                Drag.keys: ["win"]
                                Drag.source: thumb
                                Drag.hotSpot: Qt.point(width / 2, height / 2)
                                onZChanged: card.holding = dh.active
                                DragHandler { id: dh; target: thumb; onActiveChanged: { card.holding = active; if (!active) thumb.Drag.drop() } }

                                ClippingRectangle {
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width, parent.height * thumb.modelData.ratio); height: width / thumb.modelData.ratio
                                    radius: 8; color: Theme.cardHigh
                                    border.width: 1; border.color: Qt.alpha(Theme.outline, 0.5)
                                    Image {
                                        anchors.centerIn: parent; width: Math.min(32, parent.height * 0.5); height: width; visible: !shot.hasContent
                                        source: Quickshell.iconPath(thumb.modelData.cls.toLowerCase(), "application-x-executable"); sourceSize: Qt.size(64, 64)
                                    }
                                    ScreencopyView {
                                        id: shot
                                        anchors.fill: parent
                                        captureSource: thumb.modelData.top ? thumb.modelData.top.wayland : null
                                        live: false; paintCursor: false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
