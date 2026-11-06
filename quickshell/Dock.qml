import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// App dock at the bottom edge: slides up when the pointer touches the edge or the handle is tapped (touch screen),
// slides away again afterwards. Click starts an app or brings its window to the front; a dot marks running apps.
PanelWindow {
    id: win
    readonly property var apps: Settings.dockApps   // edited in the dock panel (the "+" at the end, or a right click)
    property bool touched: false      // opened by tapping the handle
    readonly property bool revealed: hv.hovered || touched || Popups.dockPinned

    visible: Settings.dock && !Popups.locked
    anchors { bottom: true }
    implicitWidth: 420; implicitHeight: 120
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-dock"
    // only the pill (or, hidden, the handle strip) takes input; the rest of the window lets clicks through
    mask: Region { item: hit }

    onRevealedChanged: if (!revealed) touched = false
    Timer { id: autoHide; interval: 4500; running: win.touched && !hv.hovered; onTriggered: win.touched = false }

    function running(cls) { return ToplevelManager.toplevels.values.some(t => t.appId === cls) }
    function active(cls) { return ToplevelManager.toplevels.values.some(t => t.appId === cls && t.activated) }

    // a running app: focus its newest window on any monitor; otherwise start it
    property var pending: null
    function open(app) { pending = app; clients.running = true }
    function launch(app) { const e = DesktopEntries.byId(app.id) ?? DesktopEntries.heuristicLookup(app.name); if (e) e.execute() }
    Process {
        id: clients
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector { onStreamFinished: {
            const app = win.pending
            if (!app) return
            let list = []
            try { list = JSON.parse(text) } catch (e) {}
            const w = list.filter(c => c.class === app.cls && c.mapped).sort((a, b) => a.focusHistoryID - b.focusHistoryID)[0]
            if (w && /^0x[0-9a-f]+$/.test(w.address)) Quickshell.execDetached(["hyprctl", "eval", "qsFocusWindow(\"" + w.address + "\")"])
            else win.launch(app)
            win.touched = false
        } }
    }

    Item {
        id: hit
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: win.revealed ? pill.width + 60 : 180
        height: win.revealed ? pill.height + 36 : 14
        HoverHandler { id: hv }

        Rectangle {   // the handle: always there, so a finger has something to tap
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
            width: 64; height: 5; radius: 2.5
            color: Qt.alpha(Theme.on_surface, 0.35)
            opacity: win.revealed ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }
        TapHandler { enabled: !win.revealed; onTapped: win.touched = true }
        TapHandler { acceptedButtons: Qt.RightButton; onTapped: { win.touched = false; Popups.toggle("dockapps", win.screen.name, win.screen.width / 2) } }   // right click: edit the dock
        DragHandler { target: null; enabled: !win.revealed; onTranslationChanged: if (translation.y < -24) win.touched = true }   // swipe up from the bottom edge

        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: win.revealed ? 12 : -height - 6
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
            width: row.implicitWidth + 28; height: 72; radius: 24
            color: Qt.alpha(Theme.surface_container, 0.82)
            border.width: 1; border.color: Qt.alpha(Theme.outline_variant, 0.6)
            opacity: win.revealed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 10
                Repeater {
                    model: win.apps
                    delegate: Item {
                        id: tile
                        required property var modelData
                        readonly property bool on: win.running(modelData.cls)
                        Layout.preferredWidth: 52; Layout.preferredHeight: 56
                        Image {
                            id: ic
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 2; width: 44; height: 44
                            sourceSize: Qt.size(88, 88)
                            source: tile.modelData.icon.indexOf("/") === 0 ? "file://" + tile.modelData.icon : Quickshell.iconPath(tile.modelData.icon, "application-x-executable")
                            transformOrigin: Item.Bottom
                            scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.25 : 1)
                            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                            SequentialAnimation { id: bounce
                                NumberAnimation { target: ic; property: "y"; to: -10; duration: 140; easing.type: Easing.OutCubic }
                                NumberAnimation { target: ic; property: "y"; to: 2; duration: 260; easing.type: Easing.OutBounce } }
                        }
                        Rectangle {   // running / focused marker
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                            height: 5; radius: 2.5
                            width: win.active(tile.modelData.cls) ? 16 : 5
                            color: Theme.accent
                            opacity: tile.on ? 1 : 0
                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                        Rectangle {   // name above the icon while hovered
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: 14 }
                            width: tip.implicitWidth + 16; height: 24; radius: 8
                            color: Qt.alpha(Theme.surface_container_high, 0.95)
                            opacity: ma.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                            Text { id: tip; anchors.centerIn: parent; textFormat: Text.PlainText; text: tile.modelData.name
                                   color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11 }
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: mouse => { bounce.restart(); if (mouse.button === Qt.MiddleButton) win.launch(tile.modelData); else win.open(tile.modelData) }
                        }
                    }
                }
                Rectangle {   // "+": opens the dock editor
                    Layout.preferredWidth: 34; Layout.preferredHeight: 34; Layout.alignment: Qt.AlignVCenter
                    radius: 17; color: pm.containsMouse ? Theme.cardHigh : "transparent"
                    border.width: 1; border.color: Qt.alpha(Theme.outline, 0.6)
                    Icon { anchors.centerIn: parent; name: "add"; size: 20; color: Theme.on_surface_variant }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true
                                onClicked: { win.touched = false; Popups.toggle("dockapps", win.screen.name, win.screen.width / 2) } }
                }
            }
        }
    }
}
