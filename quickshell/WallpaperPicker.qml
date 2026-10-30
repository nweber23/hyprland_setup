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

    readonly property real cardW: 300
    readonly property real cardH: 170
    readonly property real skew: 0.22        // horizontal shear of the cards
    readonly property var filters: ["all", "dark", "red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink", "mono"]
    property string filter: "all"
    property var items: []                   // everything the indexer found
    property bool indexing: false
    property string current: ""              // wallpaper in use
    readonly property var visibleItems: filter === "all" ? items : items.filter(i => i.tags.indexOf(filter) >= 0)

    visible: shown || strip.opacity > 0.01
    anchors { left: true; right: true }
    implicitHeight: 330
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
    }

    Rectangle {
        id: strip
        anchors.fill: parent
        color: Qt.alpha(Theme.surface, 0.82)
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        FocusScope {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Popups.close()
            Keys.onReturnPressed: win.apply(win.visibleItems[list.currentIndex])
            Keys.onEnterPressed: win.apply(win.visibleItems[list.currentIndex])
            Keys.onLeftPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
            Keys.onRightPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)

            // ---- colour filter chips ----
            Row {
                id: chips
                anchors { top: parent.top; topMargin: 18; horizontalCenter: parent.horizontalCenter }
                spacing: 6
                Repeater {
                    model: win.filters
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool active: win.filter === modelData
                        width: label.implicitWidth + 24; height: 28; radius: 14
                        color: active ? Theme.primary_container : Qt.alpha(Theme.surface_container_high, 0.8)
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Text { id: label; anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData
                               color: active ? Theme.on_primary_container : Theme.on_surface_variant
                               font.family: "JetBrains Mono"; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; onClicked: win.filter = modelData }
                    }
                }
            }

            ListView {
                id: list
                anchors { left: parent.left; right: parent.right; top: chips.bottom; topMargin: 14; bottom: nameLabel.top }
                orientation: ListView.Horizontal
                model: win.visibleItems
                spacing: 0
                clip: false
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width / 2 - win.cardW / 2
                preferredHighlightEnd: width / 2 + win.cardW / 2
                highlightMoveDuration: 320
                highlightMoveVelocity: -1
                cacheBuffer: 1200
                // Wheel steps one card
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
                    z: isCurrent ? 2 : 1   // the chosen card overlaps its neighbours, not the other way round
                    width: win.cardW * 0.78 + 34; height: ListView.view.height

                    // The slanted card: a shear matrix turns the rectangle into a parallelogram.
                    Item {
                        id: shape
                        anchors.centerIn: parent
                        width: win.cardW; height: win.cardH
                        scale: card.isCurrent ? 1.0 : 0.78
                        opacity: card.isCurrent ? 1.0 : 0.65
                        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        transform: Matrix4x4 { matrix: Qt.matrix4x4(1, -win.skew, 0, win.skew * shape.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                        layer.enabled: true
                        layer.smooth: true
                        layer.samples: 4

                        Image {
                            anchors.fill: parent
                            source: "file://" + card.modelData.thumb
                            sourceSize: Qt.size(480, 270)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.width: card.isCurrent ? 3 : (card.inUse ? 2 : 0)
                            border.color: card.isCurrent ? Theme.primary : Theme.tertiary
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
                anchors { bottom: parent.bottom; bottomMargin: 14; horizontalCenter: parent.horizontalCenter }
                textFormat: Text.PlainText
                text: win.indexing && win.items.length === 0 ? "Indexing wallpapers…"
                    : win.visibleItems.length === 0 ? "No wallpapers in ~/Pictures/Wallpapers"
                    : win.visibleItems[list.currentIndex] ? win.visibleItems[list.currentIndex].name + "   (" + (list.currentIndex + 1) + "/" + win.visibleItems.length + ")" : ""
                color: Theme.on_surface_variant
                font.family: "JetBrains Mono"; font.pixelSize: 12
            }
        }
    }
}
