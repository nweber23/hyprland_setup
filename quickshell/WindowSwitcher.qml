import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Alt+Tab / Super+Tab window switcher. Tab or Down moves on, Shift+Tab or Up back, releasing Alt/Super or
// Enter focuses the window, Delete closes it, Escape cancels. Starts on the previous window, like Alt+Tab elsewhere.
PanelWindow {
    id: win
    property string screenName: ""
    readonly property bool shown: Popups.current === "switcher" && Popups.screenName === screenName

    property var windows: []
    function refresh() {
        Hyprland.refreshToplevels()
        collect.restart()   // lastIpcObject is filled asynchronously
    }
    function collectNow() {
        const out = []
        for (const t of Hyprland.toplevels.values) {
            const o = t.lastIpcObject
            if (!o || !o.mapped || o.hidden || !o.address) continue
            out.push({ address: o.address, cls: o.class || "", title: o.title || o.class || "Window",
                       ws: o.workspace ? o.workspace.name : "", order: o.focusHistoryID })
        }
        out.sort((a, b) => a.order - b.order)   // most recently used first
        const first = windows.length === 0
        windows = out
        if (first) list.currentIndex = out.length > 1 ? 1 : 0
        else list.currentIndex = Math.min(list.currentIndex, out.length - 1)
    }
    function pick() {
        const w = windows[list.currentIndex]
        if (w) Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + w.address + "\" })"])
        Popups.close()
    }
    function closeWindow() {
        const w = windows[list.currentIndex]
        if (!w) return
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.close({ window = \"address:" + w.address + "\" })"])
        windows = windows.filter(x => x !== w)
    }
    function step(d) {
        if (windows.length === 0) return
        list.currentIndex = (list.currentIndex + d + windows.length) % windows.length
    }

    Connections { target: Popups; function onSwitchStep(d) { if (win.shown) win.step(d) } }
    Timer { id: collect; interval: 60; onTriggered: win.collectNow() }

    visible: shown || card.opacity > 0.01
    anchors { top: true }
    margins.top: 160
    implicitWidth: Math.min(1000, Math.max(420, windows.length * 190 + 40))
    implicitHeight: card.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-panel"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    HyprlandFocusGrab { windows: [win]; active: win.shown; onCleared: Popups.close() }

    onShownChanged: if (shown) { windows = []; refresh(); keys.forceActiveFocus() }

    Rectangle {
        id: card
        width: parent.width
        height: 150
        radius: 24
        color: Qt.alpha(Theme.surface_container, 0.96)
        border.width: 1; border.color: Qt.alpha(Theme.outline_variant, 0.6)
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.95
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        FocusScope {
            id: keys
            anchors.fill: parent
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Tab) win.step(1)
                else if (event.key === Qt.Key_Backtab) win.step(-1)
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) win.step(1)
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) win.step(-1)
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.pick()
                else if (event.key === Qt.Key_Delete) win.closeWindow()
                else if (event.key === Qt.Key_Escape) Popups.close()
                else return
                event.accepted = true
            }
            // letting go of the modifier that opened the switcher confirms, as in every Alt+Tab
            Keys.onReleased: event => { if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L) { win.pick(); event.accepted = true } }

            ListView {
                id: list
                anchors { fill: parent; margins: 14 }
                orientation: ListView.Horizontal
                spacing: 8; clip: true
                model: win.windows
                highlightMoveDuration: 120
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: 176; height: ListView.view.height; radius: 18
                    color: ListView.isCurrentItem ? Theme.primary_container : (hover.containsMouse ? Theme.surface_container_high : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                    ColumnLayout {
                        anchors { fill: parent; margins: 10 }
                        spacing: 6
                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 44; Layout.preferredHeight: 44
                            sourceSize: Qt.size(88, 88)
                            source: Quickshell.iconPath(modelData.cls.toLowerCase(), "application-x-executable")
                        }
                        Text {
                            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap; textFormat: Text.PlainText
                            text: modelData.title
                            color: ListView.isCurrentItem ? Theme.on_primary_container : Theme.on_surface
                            font.family: "JetBrains Mono"; font.pixelSize: 11
                        }
                        Text {
                            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; textFormat: Text.PlainText
                            text: modelData.cls + (modelData.ws !== "" ? "  ·  " + modelData.ws : "")
                            elide: Text.ElideRight; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 9
                        }
                    }
                    Icon { name: "close"; size: 18; color: Theme.on_surface_variant; opacity: hover.containsMouse ? 1 : 0
                           anchors { top: parent.top; right: parent.right; margins: 6 }
                           MouseArea { anchors.fill: parent; onClicked: { list.currentIndex = index; win.closeWindow() } } }
                    MouseArea {
                        id: hover
                        anchors.fill: parent; hoverEnabled: true; z: -1
                        onEntered: list.currentIndex = index
                        onClicked: { list.currentIndex = index; win.pick() }
                    }
                }
            }
            Text { visible: win.windows.length === 0; anchors.centerIn: parent; textFormat: Text.PlainText
                   text: "No open windows"; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 12 }
        }
    }
}
