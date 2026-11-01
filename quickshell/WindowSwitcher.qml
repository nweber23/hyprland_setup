import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Alt+Tab / Super+Tab overview: every window as a live-looking tile in a grid over a dimmed, blurred screen.
// Tab / Shift+Tab or the arrows move, releasing Alt/Super (a Hyprland release bind) or Enter switches, Delete closes, Escape cancels.
// The grid appears on the focused screen; other screens are only dimmed. Starts on the previous window.
PanelWindow {
    id: win
    property string screenName: ""
    readonly property bool active: Popups.current === "switcher"
    readonly property bool shown: active && Popups.screenName === screenName   // this screen holds the grid and the keys

    property var windows: []
    readonly property int count: windows.length
    readonly property bool manyScreens: Hyprland.monitors.values.length > 1

    // ---- window list ----
    // Asked from Hyprland itself every time: the toplevel objects cache their data, and a stale focus order made a quick
    // Alt+Tab pick the window that was already focused.
    property bool loading: false
    property string recent: ""       // address of the window picked last
    property real recentAt: 0
    // Hover only selects after the pointer really moved: tiles animating under a resting pointer also produce
    // position events, and those used to override the keyboard selection.
    property real mx: -1
    property real my: -1
    function refresh() { if (!listing.running) { loading = true; listing.running = true } }
    function monitorName(id) {
        const m = Hyprland.monitors.values.find(x => x.id === id)
        return m ? m.name : ""
    }
    function noPrefix(a) { return String(a).replace(/^0x/, "") }
    function build(json) {
        let clients = []
        try { clients = JSON.parse(json) } catch (e) {}
        const tops = Hyprland.toplevels.values
        const out = []
        for (const o of clients) {
            if (!o.mapped || o.hidden || !o.address) continue
            out.push({ top: tops.find(t => noPrefix(t.address) === noPrefix(o.address)) ?? null, address: o.address,
                       cls: o.class || "", title: o.title || o.class || "Window",
                       ws: o.workspace ? o.workspace.name : "", mon: monitorName(o.monitor),
                       ratio: o.size && o.size[1] > 0 ? o.size[0] / o.size[1] : 1.6, order: o.focusHistoryID })
        }
        out.sort((a, b) => a.order - b.order)   // most recently used first: index 0 is the focused window
        // A second tap right after a switch: Hyprland may not have moved the focus yet, so trust our own last pick.
        if (recent !== "" && Date.now() - recentAt < 700) {
            const i = out.findIndex(w => w.address === recent)
            if (i > 0) out.unshift(out.splice(i, 1)[0])
        }
        const first = windows.length === 0
        windows = out
        grid.currentIndex = first ? (out.length > 1 ? 1 : 0) : Math.min(grid.currentIndex, out.length - 1)
        if (queued !== 0 && out.length > 0) grid.currentIndex = (((grid.currentIndex + queued) % out.length) + out.length) % out.length
        queued = 0
        loading = false
        if (pendingPick) { pendingPick = false; late.restart() }   // the grid takes its new index a moment after the model
    }
    Process {
        id: listing
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector { onStreamFinished: win.build(text) }
    }
    function pick() {
        const w = windows[grid.currentIndex]
        if (w) { recent = w.address; recentAt = Date.now(); if (/^0x[0-9a-f]+$/.test(w.address)) Quickshell.execDetached(["hyprctl", "eval", "qsFocusWindow(\"" + w.address + "\")"]) }   // also switches the other monitors
        Popups.close()
    }
    function closeWindow() {
        const w = windows[grid.currentIndex]
        if (!w) return
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.close({ window = \"address:" + w.address + "\" })"])
        windows = windows.filter(x => x !== w)
    }
    // Released before the list was ready (a quick tap): switch as soon as it is.
    property bool pendingPick: false
    function confirm() {
        if (loading || count === 0) pendingPick = true; else pick()
    }
    Connections { target: Popups; function onSwitchConfirm() { if (win.shown) win.confirm() } }
    // Steps that arrive before the list is loaded (a fast double tap) are queued, not dropped.
    property int queued: 0
    function step(d) {
        if (loading || count === 0) { queued += d; return }
        grid.currentIndex = (grid.currentIndex + d + count) % count
    }
    Connections { target: Popups; function onSwitchStep(d) { if (win.shown) win.step(d) } }
    Timer { id: late; interval: 80; onTriggered: win.pick() }
    onShownChanged: if (shown) { mx = -1; pendingPick = false; queued = Popups.initSteps; windows = []; refresh(); keys.forceActiveFocus() }

    // ---- layout: the biggest tiles that still fit; more windows than fit scroll ----
    readonly property real areaW: width - 160
    readonly property real areaH: height - 170
    readonly property real minCell: 300
    readonly property int cols: {
        const n = Math.max(1, count)
        for (let c = 1; c <= n; c++) {
            const cw = areaW / c
            if (Math.ceil(n / c) * (cw / 1.6 + 44) <= areaH) return c
        }
        return Math.max(1, Math.floor(areaW / minCell))
    }
    readonly property real cellW: Math.min(areaW / cols, 520)
    readonly property real cellH: cellW / 1.6 + 44

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
        color: Qt.alpha(Theme.surface, 0.62)
        opacity: win.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: Popups.close() }
    }

    FocusScope {
        id: keys
        anchors.fill: parent
        visible: win.shown
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab) win.step(1)
            else if (event.key === Qt.Key_Backtab) win.step(-1)
            else if (event.key === Qt.Key_Right) grid.moveCurrentIndexRight()
            else if (event.key === Qt.Key_Left) grid.moveCurrentIndexLeft()
            else if (event.key === Qt.Key_Down) grid.moveCurrentIndexDown()
            else if (event.key === Qt.Key_Up) grid.moveCurrentIndexUp()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.pick()
            else if (event.key === Qt.Key_Delete) win.closeWindow()
            else if (event.key === Qt.Key_Escape) Popups.close()
            else return
            event.accepted = true
        }
        // releasing Alt/Super confirms: see switcherConfirm (a Hyprland release bind), this surface never sees that key release

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 52 }
            textFormat: Text.PlainText
            text: win.count + (win.count === 1 ? " window" : " windows") + "   ·   Tab to move   ·   Enter or release to switch   ·   Del to close"
            color: Qt.alpha(Theme.on_surface, 0.6); font.family: Theme.mono; font.pixelSize: 12
            opacity: win.shown ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 300 } }
        }
        Text {
            visible: win.count === 0; anchors.centerIn: parent; textFormat: Text.PlainText
            text: "No open windows"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 16
        }

        GridView {
            id: grid
            width: win.cols * win.cellW
            height: Math.min(Math.ceil(win.count / win.cols) * win.cellH, win.areaH)
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: 10 }
            cellWidth: win.cellW; cellHeight: win.cellH
            clip: true; model: win.windows
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: false
            // keyboard moves scroll smoothly instead of jumping
            onCurrentIndexChanged: {
                const top = Math.floor(currentIndex / win.cols) * win.cellH
                let y = contentY
                if (top < y) y = top
                else if (top + win.cellH > y + height) y = top + win.cellH - height
                scroll.to = y; scroll.restart()
            }
            NumberAnimation { id: scroll; target: grid; property: "contentY"; duration: 300; easing.type: Easing.OutCubic }

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                width: win.cellW; height: win.cellH
                readonly property bool current: GridView.isCurrentItem
                property real reveal: 0
                opacity: reveal
                transform: Translate { y: 22 * (1 - cell.reveal) }
                SequentialAnimation {   // tiles come in one after the other
                    running: true
                    PauseAnimation { duration: Math.min(cell.index, 10) * 32 }
                    NumberAnimation { target: cell; property: "reveal"; to: 1; duration: 380; easing.type: Easing.OutCubic }
                }

                ClippingRectangle {
                    id: tile
                    x: 12; y: 6; width: parent.width - 24; height: width / 1.6
                    radius: 16; color: Theme.card
                    border.width: cell.current ? 3 : 1; border.color: cell.current ? Theme.accent : Qt.alpha(Theme.outline_variant, 0.7)
                    Behavior on border.color { ColorAnimation { duration: 160 } }
                    scale: (cell.current ? 1.035 : (hover.containsMouse ? 1.015 : 1)) * (0.94 + 0.06 * cell.reveal)
                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

                    Image {   // shown until the first frame arrives
                        anchors.centerIn: parent; width: 56; height: 56; visible: !shot.hasContent
                        source: Quickshell.iconPath(cell.modelData.cls.toLowerCase(), "application-x-executable"); sourceSize: Qt.size(112, 112)
                    }
                    ScreencopyView {   // one frame at open, not a stream: cheap on a small laptop
                        id: shot
                        anchors.centerIn: parent
                        width: Math.min(tile.width, tile.height * cell.modelData.ratio)
                        height: width / cell.modelData.ratio
                        captureSource: cell.modelData.top ? cell.modelData.top.wayland : null
                        live: false; paintCursor: false
                    }
                    Rectangle {   // close button
                        anchors { top: parent.top; right: parent.right; margins: 8 }
                        width: 28; height: 28; radius: 14
                        color: closeMa.containsMouse ? Theme.error : Qt.alpha(Theme.surface, 0.8)
                        opacity: hover.containsMouse || cell.current ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                        Icon { anchors.centerIn: parent; name: "close"; size: 16; color: closeMa.containsMouse ? Theme.panelBg : Theme.on_surface }
                        MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { grid.currentIndex = cell.index; win.closeWindow() } }
                    }
                }
                RowLayout {   // icon, title, workspace
                    x: 18; y: tile.y + tile.height + 10; width: parent.width - 36; spacing: 8
                    Image { Layout.preferredWidth: 20; Layout.preferredHeight: 20; sourceSize: Qt.size(40, 40)
                            source: Quickshell.iconPath(cell.modelData.cls.toLowerCase(), "application-x-executable") }
                    Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: cell.modelData.title
                           color: cell.current ? Theme.on_surface : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12; font.bold: cell.current
                           Behavior on color { ColorAnimation { duration: 160 } } }
                    Text { textFormat: Text.PlainText; color: Theme.outline; font.family: Theme.mono; font.pixelSize: 11
                           text: cell.modelData.ws + (win.manyScreens && cell.modelData.mon !== "" ? " · " + cell.modelData.mon : "") }
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent; hoverEnabled: true; z: -1
                    onPositionChanged: mouse => {
                        const g = mapToItem(null, mouse.x, mouse.y)
                        if (win.mx < 0) { win.mx = g.x; win.my = g.y; return }   // first event: remember where the pointer rests
                        if (Math.abs(g.x - win.mx) + Math.abs(g.y - win.my) > 4) { win.mx = g.x; win.my = g.y; grid.currentIndex = cell.index }
                    }
                    onClicked: { grid.currentIndex = cell.index; win.pick() }
                }
            }
        }
    }
}
