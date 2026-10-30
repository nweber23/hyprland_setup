import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Wallpaper carousel: slanted cards, colour filters. Arrows/wheel browse, Enter applies, Esc closes.
PanelWindow {
    id: win
    property string screenName: ""
    readonly property bool shown: Popups.current === "wallpaper" && Popups.screenName === screenName

    readonly property real curW: 520         // the chosen card is wide, the others are narrow slants
    readonly property real curH: 300
    readonly property real sideW: 150
    readonly property real sideH: 250
    readonly property real skew: 0.22        // horizontal shear of the cards
    // colour filters as dots (tag in the index, dot colour)
    readonly property var dots: [
        { tag: "red", c: "#e8492b" }, { tag: "orange", c: "#f29a1f" }, { tag: "yellow", c: "#f1d12c" },
        { tag: "green", c: "#3fb549" }, { tag: "cyan", c: "#2fb4d6" }, { tag: "blue", c: "#3f7df0" },
        { tag: "purple", c: "#8b45e0" }, { tag: "pink", c: "#ee5fa5" }, { tag: "mono", c: "#9b9b9b" }, { tag: "dark", c: "#2a2a2a" }
    ]
    property string filter: "all"
    property var items: []                   // everything the indexer found
    property bool indexing: false
    property string current: ""              // wallpaper in use
    readonly property var visibleItems: filter === "all" ? items : items.filter(i => i.tags.indexOf(filter) >= 0)

    // intro: filter bar drops in, cards rise one after the other starting at the middle
    property real intro: 0
    NumberAnimation { id: introAnim; target: win; property: "intro"; to: 1; duration: 900; easing.type: Easing.OutQuart }
    SequentialAnimation { id: outAnim; NumberAnimation { target: win; property: "intro"; to: 0; duration: 200; easing.type: Easing.InQuart } }

    visible: shown || intro > 0.004
    anchors { left: true; right: true }
    implicitHeight: 440
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-panel"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    HyprlandFocusGrab { windows: [win]; active: win.shown; onCleared: Popups.close() }

    Process {
        id: indexer
        command: ["wallpaper-index"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { win.items = JSON.parse(text) } catch (e) { win.items = [] }
                win.indexing = false
                win.jumpToCurrent()
            }
        }
    }
    FileView {
        id: cur
        path: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper.txt"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: win.current = text().trim()
    }
    function jumpToCurrent() {
        const i = visibleItems.findIndex(x => x.path === current)
        list.currentIndex = i >= 0 ? i : 0
        list.positionViewAtIndex(list.currentIndex, ListView.Center)
    }
    function apply(item) {
        if (!item) return
        Quickshell.execDetached(["set-wallpaper", item.path])
        Popups.close()
    }
    onFilterChanged: Qt.callLater(jumpToCurrent)
    onShownChanged: if (shown) {
        indexing = true       // re-run every time: picks up new files, cached ones are cheap
        indexer.running = true
        keys.forceActiveFocus()
        outAnim.stop(); introAnim.restart()
    } else { introAnim.stop(); outAnim.restart() }

    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Popups.close()
        Keys.onReturnPressed: win.apply(win.visibleItems[list.currentIndex])
        Keys.onEnterPressed: win.apply(win.visibleItems[list.currentIndex])
        Keys.onLeftPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
        Keys.onRightPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)

        // ---- floating filter bar ----
        Rectangle {
            id: bar
            anchors.horizontalCenter: parent.horizontalCenter
            y: 4 - 24 * (1 - win.intro)
            opacity: win.intro
            implicitHeight: 40; implicitWidth: barRow.implicitWidth + 20; radius: 12
            color: Qt.alpha(Theme.panelBg, 0.94)
            Row {
                id: barRow
                anchors.centerIn: parent
                spacing: 10
                Rectangle {   // "all"
                    width: 28; height: 28; radius: 8; anchors.verticalCenter: parent.verticalCenter
                    color: win.filter === "all" ? Theme.accent : Theme.card
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Icon { anchors.centerIn: parent; name: "grid_view"; size: 16; color: win.filter === "all" ? Theme.panelBg : Theme.on_surface }
                    MouseArea { anchors.fill: parent; onClicked: win.filter = "all" }
                }
                Rectangle {   // animated wallpapers only
                    width: 28; height: 28; radius: 8; anchors.verticalCenter: parent.verticalCenter
                    color: win.filter === "animated" ? Theme.accent : Theme.card
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Icon { anchors.centerIn: parent; name: "play_arrow"; size: 18; fill: 1; color: win.filter === "animated" ? Theme.panelBg : Theme.on_surface }
                    MouseArea { anchors.fill: parent; onClicked: win.filter = win.filter === "animated" ? "all" : "animated" }
                }
                Repeater {
                    model: win.dots
                    delegate: Item {
                        required property var modelData
                        readonly property bool on: win.filter === modelData.tag
                        width: 22; height: 28; anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            anchors.centerIn: parent
                            width: on ? 22 : 18; height: width; radius: width / 2
                            color: modelData.c
                            border.width: on ? 2 : 0; border.color: Theme.on_surface
                            scale: dotArea.containsMouse ? 1.15 : 1
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                            Behavior on scale { NumberAnimation { duration: 120 } }
                        }
                        MouseArea { id: dotArea; anchors.fill: parent; hoverEnabled: true; onClicked: win.filter = on ? "all" : modelData.tag }
                    }
                }
            }
        }

        ListView {
            id: list
            anchors { left: parent.left; right: parent.right; top: bar.bottom; topMargin: 30; bottom: nameLabel.top }
            orientation: ListView.Horizontal
            model: win.visibleItems
            spacing: 0
            clip: false
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - win.curW / 2
            preferredHighlightEnd: width / 2 + win.curW / 2
            highlightMoveDuration: 420
            highlightMoveVelocity: -1
            cacheBuffer: 1600
            WheelHandler {
                onWheel: event => {
                    const d = (event.angleDelta.y + event.angleDelta.x) > 0 ? -1 : 1
                    list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + d))
                }
            }
            delegate: Item {
                id: card
                required property var modelData
                required property int index
                readonly property bool isCurrent: ListView.isCurrentItem
                readonly property bool inUse: modelData.path === win.current
                // staggered rise: the further from the middle card, the later it starts
                readonly property real rise: Math.max(0, Math.min(1, win.intro * 1.6 - Math.min(5, Math.abs(index - list.currentIndex)) * 0.12))
                z: isCurrent ? 2 : 1
                width: (isCurrent ? win.curW : win.sideW) + 14
                height: ListView.view.height
                Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

                Item {
                    id: shape
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 14
                    height: card.isCurrent ? win.curH : win.sideH
                    y: (parent.height - height) / 2 + 70 * (1 - card.rise)
                    opacity: card.rise            // side cards are dimmed by the dark overlay, not by transparency
                    Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    transform: Matrix4x4 { matrix: Qt.matrix4x4(1, -win.skew, 0, win.skew * shape.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                    layer.enabled: true; layer.smooth: true; layer.samples: 4

                    Image {
                        anchors.fill: parent
                        source: card.isCurrent && !card.modelData.video ? "file://" + card.modelData.path : "file://" + card.modelData.thumb
                        sourceSize: card.isCurrent ? Qt.size(1040, 600) : Qt.size(300, 500)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Icon { visible: card.modelData.video === true; anchors { right: parent.right; top: parent.top; margins: 8 }
                           name: "play_circle"; size: 22; color: "white"; opacity: 0.9 }   // marks an animated wallpaper
                    Rectangle { anchors.fill: parent; color: "#000"; opacity: card.isCurrent ? 0 : 0.3
                                Behavior on opacity { NumberAnimation { duration: 300 } } }
                    Rectangle {
                        anchors.fill: parent; color: "transparent"
                        border.width: card.isCurrent ? 3 : (card.inUse ? 2 : 0)
                        border.color: card.isCurrent ? Theme.accent2 : Theme.accent
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: card.isCurrent ? win.apply(card.modelData) : list.currentIndex = card.index
                }
            }
        }

        Text {
            id: nameLabel
            anchors { bottom: parent.bottom; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
            opacity: win.intro
            textFormat: Text.PlainText
            text: win.indexing && win.items.length === 0 ? "Indexing wallpapers…"
                : win.visibleItems.length === 0 ? "No wallpapers match"
                : win.visibleItems[list.currentIndex] ? win.visibleItems[list.currentIndex].name + "   " + (list.currentIndex + 1) + "/" + win.visibleItems.length : ""
            color: Theme.on_surface; style: Text.Outline; styleColor: Qt.alpha("#000", 0.6)
            font.family: Theme.mono; font.pixelSize: 12
        }
    }
}
