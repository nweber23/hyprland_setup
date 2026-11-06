import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Screenshot editor: a region screenshot (bin/screenshot annotate) opens here to be marked up with a pen, marker, arrows,
// boxes, text and black cover-ups. Enter saves it to ~/Pictures/Screenshots and copies it; Escape throws it away.
PanelWindow {
    id: win
    property string screenName: ""
    readonly property bool active: Popups.current === "annotate"
    readonly property bool shown: active && Popups.screenName === screenName

    visible: shown || scrim.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-annotate"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var colors: ["#ff3b30", "#ff9f0a", "#ffd60a", "#30d158", "#0a84ff", "#ffffff"]
    readonly property var tools: [
        { id: "pen", icon: "edit", tip: "Pen (P)" }, { id: "marker", icon: "ink_highlighter", tip: "Marker (M)" },
        { id: "arrow", icon: "north_east", tip: "Arrow (A)" }, { id: "rect", icon: "crop_square", tip: "Box (B)" },
        { id: "text", icon: "title", tip: "Text (T)" }, { id: "cover", icon: "visibility_off", tip: "Cover up (C)" }
    ]

    onShownChanged: if (shown) { canvas.reset(); canvas.source = "file://" + Popups.annotatePath; keys.forceActiveFocus() }

    function save() {
        if (!canvas.loaded || saving.running) return
        const name = "screenshot-" + Qt.formatDateTime(new Date(), "yyyy-MM-dd-HHmmss") + "-annotated.png"
        const out = Quickshell.env("HOME") + "/Pictures/Screenshots/" + name
        canvas.exportPng(out, ok => {
            if (!ok) { Popups.close(); return }
            saving.command = ["sh", "-c", 'wl-copy -t image/png < "$1"; notify-send -a Screenshot -i "$1" "Screenshot saved" "$2 - also in the clipboard"', "sh", out, name]
            saving.running = true
            Popups.close()
        })
    }
    Process { id: saving }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.alpha(Theme.surface, 0.86)
        opacity: win.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }   // swallows clicks on the dark area
    }

    FocusScope {
        id: keys
        anchors.fill: parent
        visible: win.shown
        Keys.onPressed: event => {
            if (canvas.editingText) return
            const k = event.key
            if (k === Qt.Key_Escape) Popups.close()
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) win.save()
            else if (k === Qt.Key_Z && (event.modifiers & Qt.ControlModifier)) canvas.undo()
            else if (k === Qt.Key_P) canvas.tool = "pen"
            else if (k === Qt.Key_M) canvas.tool = "marker"
            else if (k === Qt.Key_A) canvas.tool = "arrow"
            else if (k === Qt.Key_B) canvas.tool = "rect"
            else if (k === Qt.Key_T) canvas.tool = "text"
            else if (k === Qt.Key_C) canvas.tool = "cover"
            else return
            event.accepted = true
        }

        // the picture, shrunk to fit if it is bigger than the screen; drawing happens at its real size inside
        Item {
            id: stage
            readonly property real fit: canvas.width > 0 ? Math.min(1, (win.width - 80) / canvas.width, (win.height - 190) / canvas.height) : 1
            width: canvas.width * fit; height: canvas.height * fit
            x: (win.width - width) / 2; y: (win.height - 110 - height) / 2
            opacity: win.shown && canvas.loaded ? 1 : 0
            scale: win.shown && canvas.loaded ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Rectangle { anchors { fill: parent; margins: -1 } color: "transparent"; border.width: 1; border.color: Qt.alpha(Theme.outline, 0.6) }
            AnnotateCanvas {
                id: canvas
                scale: stage.fit; transformOrigin: Item.TopLeft
            }
        }

        // toolbar
        Rectangle {
            id: bar
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 36 }
            implicitWidth: row.implicitWidth + 28; implicitHeight: 56; radius: 28
            color: Theme.panelBg; border.width: 1; border.color: Qt.alpha(Theme.outline_variant, 0.7)
            opacity: win.shown ? 1 : 0
            transform: Translate { y: win.shown ? 0 : 24; Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } } }
            Behavior on opacity { NumberAnimation { duration: 260 } }
            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                    model: win.tools
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool on: canvas.tool === modelData.id
                        implicitWidth: 40; implicitHeight: 40; radius: 20
                        color: on ? Theme.accent : (tm.containsMouse ? Theme.cardHigh : "transparent")
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Icon { anchors.centerIn: parent; name: modelData.icon; size: 22; color: parent.on ? Theme.panelBg : Theme.on_surface }
                        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; onClicked: canvas.tool = modelData.id }
                    }
                }
                Rectangle { implicitWidth: 1; implicitHeight: 26; color: Theme.cardHigh }
                Repeater {
                    model: win.colors
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool on: String(canvas.color).toLowerCase() === modelData
                        implicitWidth: 26; implicitHeight: 26; radius: 13; color: modelData
                        border.width: on ? 3 : 1; border.color: on ? Theme.on_surface : Qt.alpha("white", 0.3)
                        scale: on ? 1.15 : 1
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                        MouseArea { anchors.fill: parent; onClicked: canvas.color = modelData }
                    }
                }
                Rectangle { implicitWidth: 1; implicitHeight: 26; color: Theme.cardHigh }
                Repeater {
                    model: [3, 6, 11]
                    delegate: Rectangle {
                        required property int modelData
                        readonly property bool on: canvas.size === modelData
                        implicitWidth: 34; implicitHeight: 34; radius: 17
                        color: on ? Theme.cardHigh : "transparent"
                        Rectangle { anchors.centerIn: parent; width: 6 + modelData * 1.3; height: width; radius: width / 2; color: Theme.on_surface }
                        MouseArea { anchors.fill: parent; onClicked: canvas.size = modelData }
                    }
                }
                Rectangle { implicitWidth: 1; implicitHeight: 26; color: Theme.cardHigh }
                Rectangle {   // undo
                    implicitWidth: 40; implicitHeight: 40; radius: 20
                    color: um.containsMouse ? Theme.cardHigh : "transparent"
                    Icon { anchors.centerIn: parent; name: "undo"; size: 22; color: Theme.on_surface }
                    MouseArea { id: um; anchors.fill: parent; hoverEnabled: true; onClicked: canvas.undo() }
                }
                Rectangle {   // save and copy
                    implicitWidth: 40; implicitHeight: 40; radius: 20; color: Theme.primary
                    scale: sm.containsMouse ? 1.1 : 1
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                    Icon { anchors.centerIn: parent; name: "check"; size: 24; color: Theme.on_primary }
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; onClicked: win.save() }
                }
                Rectangle {   // discard
                    implicitWidth: 40; implicitHeight: 40; radius: 20
                    color: cm.containsMouse ? Theme.error : "transparent"
                    Icon { anchors.centerIn: parent; name: "close"; size: 22; color: cm.containsMouse ? Theme.panelBg : Theme.on_surface }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: Popups.close() }
                }
            }
        }
    }
}
