import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// Widgets on the bare desktop: clock with weather, battery and the playing track. They sit below all windows
// (layer Bottom) and only take clicks where a widget is, so the desktop behind stays usable.
PanelWindow {
    id: win
    visible: !Popups.locked          // also without widgets: the right-click menu lives here
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-widgets"
    color: "transparent"
    mask: Region { item: desk }   // the whole bare desktop takes the right click; the widgets lie on top and keep theirs

    readonly property var player: {
        const ps = Mpris.players.values
        for (let i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i]
        return ps.length > 0 ? ps[0] : null
    }
    readonly property var battery: UPower.displayDevice
    readonly property int percent: Math.round(Battery.pct)
    readonly property bool charging: battery && battery.state === UPowerDeviceState.Charging

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Item { id: desk; anchors.fill: parent }

    // ---- where the widgets sit: defaults, or what was dragged (stored per screen in Settings.widgetLayout) ----
    property bool editing: false
    property string dragId: ""          // the widget being dragged right now, with its live offset and scale
    property real dragDx: 0
    property real dragDy: 0
    property real dragS: 1
    readonly property var defaults: ({
        clock: { x: 56, y: 96 },
        battery: { x: 56, y: win.height - 76 - 56 },
        music: { x: 56 + 210 + 16, y: win.height - 76 - 56 }
    })
    function stored(id) { return Settings.widgetLayout[win.screen.name + ":" + id] ?? null }
    function baseX(id) { const l = stored(id); return l ? l.x : defaults[id].x }
    function baseY(id) { const l = stored(id); return l ? l.y : defaults[id].y }
    function scaleOf(id) { if (dragId === id) return dragS; const l = stored(id); return l && l.s ? l.s : 1 }
    function posX(id) { return baseX(id) + (dragId === id ? dragDx : 0) }
    function posY(id) { return baseY(id) + (dragId === id ? dragDy : 0) }
    function commit(id, x, y, s) {
        const m = Object.assign({}, Settings.widgetLayout)
        m[win.screen.name + ":" + id] = { x: Math.round(x), y: Math.round(y), s: Math.round(s * 100) / 100 }
        Settings.set("widgetLayout", m)
    }
    function resetLayout() {
        const m = {}
        for (const k in Settings.widgetLayout) if (k.indexOf(win.screen.name + ":") !== 0) m[k] = Settings.widgetLayout[k]
        Settings.set("widgetLayout", m)
    }

    // ---- clock + weather ----
    ColumnLayout {
        id: clockBox
        visible: Settings.widgets
        x: win.posX("clock"); y: win.posY("clock"); scale: win.scaleOf("clock"); transformOrigin: Item.TopLeft
        spacing: 0
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#99000000"; shadowBlur: 0.8; shadowVerticalOffset: 3 }
        Text { textFormat: Text.PlainText; text: Qt.formatTime(clock.date, "HH:mm"); color: "white"
               font.family: Theme.mono; font.pixelSize: 112; font.bold: true }
        Text { textFormat: Text.PlainText; text: Qt.formatDate(clock.date, "dddd, d MMMM"); color: Qt.alpha("white", 0.85)
               font.family: Theme.mono; font.pixelSize: 20 }
        RowLayout {
            visible: Weather.temp !== ""; Layout.topMargin: 6; spacing: 8
            Icon { name: Weather.icon; size: 22; color: "white" }
            Text { textFormat: Text.PlainText; text: Weather.temp + (Weather.desc !== "" ? "  ·  " + Weather.desc : ""); color: Qt.alpha("white", 0.85)
                   font.family: Theme.mono; font.pixelSize: 15 }
        }
    }

    // ---- battery ----
    Rectangle {
        id: batBox
        visible: Settings.widgets
        x: win.posX("battery"); y: win.posY("battery"); scale: win.scaleOf("battery"); transformOrigin: Item.TopLeft
        width: 210; height: 76; radius: 18
        color: Qt.alpha(Theme.surface_container, 0.75)
        border.width: 1; border.color: Qt.alpha("white", 0.1)
        RowLayout {
            anchors { fill: parent; margins: 16 }
            spacing: 12
            Icon { name: win.charging ? "battery_charging_full" : "battery_full"; size: 30; color: win.percent <= 20 && !win.charging ? Theme.error : Theme.accent }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                RowLayout {
                    Text { textFormat: Text.PlainText; text: win.percent + "%"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 20; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Text { textFormat: Text.PlainText; text: win.charging ? "charging" : "battery"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: Theme.card
                    Rectangle { width: parent.width * Math.min(1, win.percent / 100); height: parent.height; radius: 3
                                color: win.percent <= 20 && !win.charging ? Theme.error : Theme.accent
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } } }
                }
            }
        }
    }

    // the bars rise out of the top of the music card
    Row {
        id: vizBox
        visible: Settings.widgets && win.player !== null
        x: musicBox.x + 8 * musicBox.scale; y: musicBox.y - (height + 6) * musicBox.scale; scale: musicBox.scale; transformOrigin: Item.TopLeft
        width: musicBox.width - 16; height: 58
        spacing: 3
        opacity: Spectrum.levels.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
        Repeater {
            model: 24
            delegate: Item {   // a fixed-size cell: items inside a Row cannot be anchored
                required property int index
                readonly property real v: Spectrum.levels.length > index ? Spectrum.levels[index] / 100 : 0
                width: (vizBox.width - 23 * 3) / 24; height: vizBox.height
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: Math.max(3, parent.height * parent.v)
                    radius: width / 2
                    color: Qt.alpha(Theme.accent, 0.45 + 0.55 * parent.v)
                    Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                }
            }
        }
    }

    // ---- music ----
    Rectangle {
        id: musicBox
        visible: Settings.widgets && win.player !== null
        x: win.posX("music"); y: win.posY("music"); scale: win.scaleOf("music"); transformOrigin: Item.TopLeft
        width: 360; height: 76; radius: 18
        color: Qt.alpha(Theme.surface_container, 0.75)
        border.width: 1; border.color: Qt.alpha("white", 0.1)
        RowLayout {
            anchors { fill: parent; margins: 10 }
            spacing: 12
            Rectangle {
                Layout.preferredWidth: 56; Layout.preferredHeight: 56; radius: 12; color: Theme.card; clip: true
                Image { anchors.fill: parent; source: win.player ? win.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true
                        sourceSize: Qt.size(112, 112) }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                       text: win.player ? win.player.trackTitle : ""; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
                Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                       text: win.player ? win.player.trackArtist : ""; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
            }
            Repeater {
                model: [{ i: "skip_previous", a: 0 }, { i: "play", a: 1 }, { i: "skip_next", a: 2 }]
                delegate: Rectangle {
                    required property var modelData
                    Layout.preferredWidth: 34; Layout.preferredHeight: 34; radius: 17
                    color: bm.containsMouse ? Theme.cardHigh : "transparent"
                    Icon { anchors.centerIn: parent; size: 22; fill: 1; color: Theme.on_surface
                           name: modelData.a === 1 ? (win.player && win.player.isPlaying ? "pause" : "play_arrow") : modelData.i }
                    MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true
                                onClicked: { if (!win.player) return; if (modelData.a === 0) win.player.previous(); else if (modelData.a === 1) win.player.togglePlaying(); else win.player.next() } }
                }
            }
        }
    }

    // ---- edit mode: drag a widget to move it, scroll over it to resize it ----
    Repeater {
        model: win.editing ? [{ id: "clock", item: clockBox }, { id: "battery", item: batBox }, { id: "music", item: musicBox }] : []
        delegate: Rectangle {
            required property var modelData
            readonly property var it: modelData.item
            visible: it.visible
            x: it.x; y: it.y; width: it.implicitWidth * it.scale; height: it.implicitHeight * it.scale
            z: 30; radius: 14; color: Qt.alpha(Theme.accent, ma.pressed ? 0.18 : 0.08)
            border.width: 2; border.color: Theme.accent
            MouseArea {
                id: ma
                anchors.fill: parent
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property real sx: 0
                property real sy: 0
                onPressed: mouse => { const g = mapToItem(null, mouse.x, mouse.y); sx = g.x; sy = g.y
                                      win.dragId = modelData.id; win.dragDx = 0; win.dragDy = 0; win.dragS = win.scaleOf(modelData.id) }
                onPositionChanged: mouse => { if (!pressed) return; const g = mapToItem(null, mouse.x, mouse.y); win.dragDx = g.x - sx; win.dragDy = g.y - sy }
                onReleased: { const id = modelData.id; win.commit(id, win.baseX(id) + win.dragDx, win.baseY(id) + win.dragDy, win.dragS); win.dragId = "" }
                onWheel: wheel => {
                    const id = modelData.id, s = Math.max(0.6, Math.min(2.2, win.scaleOf(id) + (wheel.angleDelta.y > 0 ? 0.1 : -0.1)))
                    if (win.dragId === id) win.dragS = s; else win.commit(id, win.baseX(id), win.baseY(id), s)
                }
            }
        }
    }
    Rectangle {   // the strip at the bottom while editing
        visible: win.editing
        z: 40
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 }
        width: strip.implicitWidth + 28; height: 48; radius: 24
        color: Qt.alpha(Theme.surface_container, 0.92); border.width: 1; border.color: Qt.alpha(Theme.outline_variant, 0.7)
        RowLayout {
            id: strip
            anchors.centerIn: parent; spacing: 14
            Text { textFormat: Text.PlainText; text: "Drag to move  ·  scroll to resize"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
            Rectangle { implicitWidth: rl.implicitWidth + 24; implicitHeight: 30; radius: 15; color: rm.containsMouse ? Theme.cardHigh : Theme.card
                Text { id: rl; anchors.centerIn: parent; textFormat: Text.PlainText; text: "Reset"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12 }
                MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; onClicked: win.resetLayout() } }
            Rectangle { implicitWidth: dl.implicitWidth + 24; implicitHeight: 30; radius: 15; color: Theme.primary
                Text { id: dl; anchors.centerIn: parent; textFormat: Text.PlainText; text: "Done"; color: Theme.on_primary; font.family: Theme.mono; font.pixelSize: 12; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: win.editing = false } }
        }
    }

    // ---- right-click menu on the bare desktop ----
    property real menuX: 0
    property real menuY: 0
    property bool menuOpen: false
    readonly property var menuItems: [
        { icon: "wallpaper", text: "Change wallpaper", run: () => Popups.toggle("wallpaper", win.screen.name, win.menuX) },
        { icon: "shuffle", text: "Random wallpaper", run: () => Quickshell.execDetached(["sh", "-c",
              'f=$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) | shuf -n 1); [ -n "$f" ] && exec set-wallpaper "$f"']) },
        { sep: true },
        { icon: "terminal", text: "Terminal", run: () => Quickshell.execDetached(["kitty"]) },
        { icon: "folder", text: "Files", run: () => Quickshell.execDetached(["xdg-open", Quickshell.env("HOME")]) },
        { icon: "photo_camera", text: "Screenshot", run: () => Popups.toggle("capture", win.screen.name, win.menuX) },
        { sep: true },
        { icon: "desktop_windows", text: "Display", run: () => Popups.toggle("display", win.screen.name, win.menuX) },
        { icon: "widgets", text: Settings.widgets ? "Hide widgets" : "Show widgets", run: () => Settings.set("widgets", !Settings.widgets) },
        { icon: "drag_pan", text: "Edit widgets", run: () => { if (!Settings.widgets) Settings.set("widgets", true); win.editing = true } },
        { icon: "settings", text: "Settings", run: () => Popups.toggle("settings", win.screen.name, win.menuX) },
        { sep: true },
        { icon: "lock", text: "Lock", run: () => Quickshell.execDetached(["quickshell", "ipc", "call", "shell", "lock"]) }
    ]
    MouseArea {   // right click opens it, any click elsewhere closes it
        anchors.fill: parent; z: 5
        enabled: win.menuOpen
        acceptedButtons: Qt.AllButtons
        onPressed: win.menuOpen = false
    }
    MouseArea {
        anchors.fill: parent; z: -1
        acceptedButtons: Qt.RightButton
        onPressed: mouse => { win.menuX = mouse.x; win.menuY = mouse.y; win.menuOpen = true }
    }
    Rectangle {
        id: menu
        z: 10
        visible: opacity > 0.01
        opacity: win.menuOpen ? 1 : 0
        scale: win.menuOpen ? 1 : 0.9
        transformOrigin: Item.TopLeft
        x: Math.min(win.menuX, win.width - width - 12); y: Math.min(win.menuY, win.height - height - 12)
        width: 220; height: col.implicitHeight + 16; radius: 14
        color: Qt.alpha(Theme.surface_container, 0.92)
        border.width: 1; border.color: Qt.alpha(Theme.outline_variant, 0.7)
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
        Column {
            id: col
            x: 8; y: 8; width: parent.width - 16; spacing: 2
            Repeater {
                model: win.menuItems
                delegate: Item {
                    required property var modelData
                    width: col.width; height: modelData.sep ? 9 : 36
                    Rectangle { visible: modelData.sep === true; anchors.centerIn: parent; width: parent.width - 12; height: 1; color: Theme.cardHigh }
                    Rectangle {
                        visible: modelData.sep !== true
                        anchors.fill: parent; radius: 9
                        color: ma.containsMouse ? Theme.cardHigh : "transparent"
                        Behavior on color { ColorAnimation { duration: 110 } }
                        Row {
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                            spacing: 12
                            Icon { name: modelData.icon ?? ""; size: 20; color: ma.containsMouse ? Theme.accent : Theme.on_surface_variant
                                   anchors.verticalCenter: parent.verticalCenter }
                            Text { textFormat: Text.PlainText; text: modelData.text ?? ""; color: Theme.on_surface
                                   font.family: Theme.mono; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            id: ma; anchors.fill: parent; hoverEnabled: true
                            onClicked: { win.menuOpen = false; modelData.run() }
                        }
                    }
                }
            }
        }
    }
}
