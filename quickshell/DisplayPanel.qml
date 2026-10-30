import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// Resolution, refresh rate and scale per monitor. Changes apply at once through `hyprctl eval` and are
// saved to ~/.config/hypr/monitors-local.{json,lua}; hyprland.lua loads the .lua file after its own rules.
Panel {
    id: root
    name: "display"
    backdrop: "Aurora"
    panelWidth: 700
    centered: true

    property var monitors: []      // parsed from `hyprctl -j monitors`
    property var saved: ({})       // description -> { mode, scale }
    readonly property string dir: Quickshell.env("HOME") + "/.config/hypr/"
    readonly property var scales: [1, 1.25, 1.5, 2]

    // "1920x1080@60.04Hz" -> { w, h, r, text }
    function parseModes(list) {
        return list.map(s => { const m = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(s); return m ? { w: +m[1], h: +m[2], r: +m[3], raw: s } : null }).filter(x => x)
    }
    function resolutions(mon) {
        const seen = {}, out = []
        for (const m of mon.modes) { const k = m.w + "x" + m.h; if (!seen[k]) { seen[k] = 1; out.push({ w: m.w, h: m.h }) } }
        return out
    }
    function ratesFor(mon) { return mon.modes.filter(m => m.w === mon.width && m.h === mon.height) }

    // The description ends up inside a Lua string: refuse anything that could break out of it.
    function safe(s) { return typeof s === "string" && s.length > 0 && !/["\\\n\r]/.test(s) }

    function apply(mon, w, h, r, scale) {
        if (!safe(mon.description)) return
        const mode = w + "x" + h + "@" + r
        const pos = mon.name.startsWith("eDP") ? "0x0" : "auto-right"
        const rule = 'hl.monitor({ output = "desc:' + mon.description + '", mode = "' + mode + '", position = "' + pos + '", scale = ' + scale + ' })'
        Quickshell.execDetached(["hyprctl", "eval", rule])
        const s = Object.assign({}, saved); s[mon.description] = { mode: mode, scale: scale }; saved = s
        persist()
        reload.restart()
    }
    function persist() {
        store.setText(JSON.stringify(saved))
        let lua = "-- Written by the shell's display panel; loaded at the end of the monitor rules.\n"
        for (const d in saved) {
            if (!safe(d)) continue
            const pos = d.startsWith("AU Optronics") ? "0x0" : "auto-right"
            lua += 'hl.monitor({ output = "desc:' + d + '", mode = "' + saved[d].mode + '", position = "' + pos + '", scale = ' + saved[d].scale + ' })\n'
        }
        luaFile.setText(lua)
    }

    // Give Hyprland a moment to apply, then refresh the panel and the X11 DPI (follows the scale).
    Timer { id: reload; interval: 700; onTriggered: { Quickshell.execDetached(["xdpi"]); root.load() } }
    function load() { if (!q.running) q.running = true }
    onShownChanged: if (shown) { load(); applied = false }

    Process {
        id: q
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text).map(m => ({
                        name: m.name, description: m.description, width: m.width, height: m.height,
                        rate: m.refreshRate, scale: m.scale, modes: root.parseModes(m.availableModes)
                    }))
                } catch (e) {}
            }
        }
    }
    FileView {
        id: store
        path: root.dir + "monitors-local.json"
        printErrors: false   // missing until the first change
        onLoaded: { try { root.saved = JSON.parse(text()) } catch (e) {} }
    }
    FileView { id: luaFile; path: root.dir + "monitors-local.lua"; printErrors: false }

    // ---- what is selected in the panel (applied with the button) ----
    property int selMon: 0
    readonly property var mon: monitors.length > 0 ? monitors[Math.min(selMon, monitors.length - 1)] : null
    property int pw: 0
    property int ph: 0
    property real pr: 0
    property real pscale: 1
    property bool applied: false
    function syncPending() { if (mon) { pw = mon.width; ph = mon.height; pr = mon.rate; pscale = mon.scale } }
    onMonChanged: syncPending()
    onSelMonChanged: syncPending()

    readonly property var resList: mon ? resolutions(mon).sort((a, b) => b.w * b.h - a.w * a.h).slice(0, 8) : []
    readonly property var rateList: mon ? mon.modes.filter(m => m.w === pw && m.h === ph).map(m => m.r).sort((a, b) => a - b) : []
    // nearest listed rate to the pending one
    readonly property int rateIndex: {
        let best = 0
        for (let i = 0; i < rateList.length; i++) if (Math.abs(rateList[i] - pr) < Math.abs(rateList[best] - pr)) best = i
        return best
    }
    function nameFor(w, h) {
        const t = { "3840x2160": "4K", "2560x1440": "QHD", "1920x1080": "FHD", "1600x900": "HD+", "1366x768": "WXGA", "1280x720": "HD",
                    "1024x768": "XGA", "800x600": "SVGA", "3440x1440": "UWQHD", "2560x1080": "UWFHD", "1920x1200": "WUXGA", "1680x1050": "WSXGA+",
                    "1440x900": "WXGA+", "1280x1024": "SXGA", "1280x800": "WXGA", "640x480": "VGA", "1920x1440": "1440P", "2048x1152": "QWXGA" }
        return t[w + "x" + h] ?? (h + "p")
    }
    function pickRes(w, h) {
        pw = w; ph = h; applied = false
        const rs = mon.modes.filter(m => m.w === w && m.h === h).map(m => m.r)
        // keep a similar refresh rate when the new size offers one, else the highest
        pr = rs.find(r => Math.abs(r - pr) < 1) ?? Math.max(...rs)
    }

    // monitor picker, only when more than one is connected
    Reveal {
        p: root; index: 0; dy: 8
        visible: root.monitors.length > 1
        Row {
            spacing: 8
            Repeater {
                model: root.monitors
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool on: root.selMon === index
                    width: nm.implicitWidth + 24; height: 28; radius: 9
                    color: on ? Theme.accent : Theme.card
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text { id: nm; anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData.name
                           color: parent.on ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: root.selMon = index }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 28

        // ---- the monitor drawing ----
        Reveal {
            p: root; index: 1; dx: -30; dy: 8; back: true
            Layout.alignment: Qt.AlignVCenter; Layout.fillWidth: false
            Item {
                Layout.preferredWidth: 230; Layout.preferredHeight: 250
                // screen: its shape follows the aspect ratio of the pending resolution
                Rectangle {
                    id: screen
                    readonly property real aspect: root.ph > 0 ? root.pw / root.ph : 1.78
                    width: Math.min(220, 140 * aspect); height: width / aspect
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 30 + (140 - height) / 2
                    radius: 10; color: Theme.card; border.width: 4; border.color: Theme.cardHigh
                    // faint dot grid on the glass
                    Canvas {
                        anchors.fill: parent; anchors.margins: 6
                        onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
                        onPaint: {
                            const c = getContext("2d"); c.reset()
                            c.fillStyle = Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.09)
                            for (let x = 4; x < width; x += 14) for (let y = 4; y < height; y += 14) c.fillRect(x, y, 2, 2)
                        }
                    }
                    Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                    Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 4
                        Icon { Layout.alignment: Qt.AlignHCenter; name: "desktop_windows"; size: 34; color: Theme.accent }
                        Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: root.mon ? root.mon.name : "—"
                               color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
                        Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText
                               text: root.pw + "x" + root.ph + " @ " + Math.round(root.pr) + "Hz"
                               color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10
                               onTextChanged: textPulse.restart()
                               SequentialAnimation on opacity { id: textPulse; running: false
                                   NumberAnimation { to: 0.3; duration: 70 } NumberAnimation { to: 1; duration: 260; easing.type: Easing.OutCubic } } }
                    }
                }
                Rectangle { x: -24; y: 216; width: parent.width + 120; height: 8; radius: 4; color: Theme.card }          // desk
                Rectangle { x: (parent.width - 26) / 2; y: 176; width: 26; height: 34; color: Theme.cardHigh
                            Rectangle { x: 9; y: 8; width: 8; height: 18; radius: 4; color: Theme.card } }                   // neck with cable slot
                Rectangle { x: (parent.width - 110) / 2; y: 208; width: 110; height: 10; radius: 5; color: Theme.cardHigh } // foot
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16

            // ---- resolutions ----
            Reveal {
                p: root; index: 2; dy: 12; step: 70
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2; rowSpacing: 6; columnSpacing: 8
                    flow: GridLayout.TopToBottom; rows: 4
                    Repeater {
                        model: root.resList
                        delegate: Rectangle {
                            id: tile
                            required property var modelData
                            readonly property bool on: root.pw === modelData.w && root.ph === modelData.h
                            Layout.fillWidth: true; implicitHeight: 40; radius: 11
                            color: tArea.containsMouse ? Theme.card : "transparent"
                            scale: tArea.pressed ? 0.97 : 1
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                            // selection ring pops in with a little overshoot
                            Rectangle {
                                anchors.fill: parent; radius: 11; color: Qt.alpha(Theme.accent, 0.12)
                                border.width: 2; border.color: Theme.accent
                                opacity: tile.on ? 1 : 0; scale: tile.on ? 1 : 0.9
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                            }
                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                Text { textFormat: Text.PlainText; text: root.nameFor(tile.modelData.w, tile.modelData.h)
                                       color: tile.on ? Theme.accent : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true
                                       Behavior on color { ColorAnimation { duration: 200 } } }
                                Item { Layout.fillWidth: true }
                                Text { textFormat: Text.PlainText; text: tile.modelData.w + "x" + tile.modelData.h
                                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
                            }
                            MouseArea { id: tArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.pickRes(tile.modelData.w, tile.modelData.h) }
                        }
                    }
                }
            }

            // ---- refresh rate: a slider with one stop per available rate ----
            Reveal {
                p: root; index: 3; dy: 12
                Item {
                    id: rateSlider
                    Layout.fillWidth: true; implicitHeight: 54
                    readonly property int n: root.rateList.length
                    function posFor(i) { return n > 1 ? track.width * i / (n - 1) : track.width / 2 }
                    Rectangle {
                        id: track
                        x: 11; width: parent.width - 22; y: 6; height: 12; radius: 6; color: Theme.cardHigh
                        Rectangle { width: rateSlider.posFor(root.rateIndex); height: parent.height; radius: 6; color: Theme.accent
                                    Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } } }
                    }
                    Rectangle {
                        id: knob
                        width: 24; height: 24; radius: 12; color: Theme.on_surface; y: 0
                        x: 11 + rateSlider.posFor(root.rateIndex) - 12
                        scale: sliderArea.pressed ? 1.2 : 1
                        Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
                        Behavior on scale { NumberAnimation { duration: 120 } }
                    }
                    Repeater {
                        model: root.rateList
                        delegate: Text {
                            required property real modelData
                            required property int index
                            x: 11 + rateSlider.posFor(index) - width / 2; y: 30
                            textFormat: Text.PlainText; text: Math.round(modelData)
                            color: index === root.rateIndex ? Theme.accent : Theme.on_surface_variant
                            font.family: Theme.mono; font.pixelSize: 11; font.bold: index === root.rateIndex
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                    MouseArea {
                        id: sliderArea
                        anchors.fill: parent
                        enabled: rateSlider.n > 1
                        function pick(mx) {
                            const f = Math.max(0, Math.min(1, (mx - 11) / track.width))
                            root.pr = root.rateList[Math.round(f * (rateSlider.n - 1))]; root.applied = false
                        }
                        onPressed: mouse => pick(mouse.x)
                        onPositionChanged: mouse => { if (pressed) pick(mouse.x) }
                    }
                }
            }

            // ---- scale + apply ----
            Reveal {
                p: root; index: 4; dy: 12; back: true
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Rectangle {   // scale chips with a sliding highlight
                        implicitWidth: 4 * 52 + 3 * 4 + 8; implicitHeight: 38; radius: 11; color: Theme.card
                        Rectangle {
                            width: 52; height: 30; radius: 8; color: Theme.accent2; y: 4
                            x: 4 + Math.max(0, root.scales.findIndex(v => Math.abs(v - root.pscale) < 0.01)) * 56
                            Behavior on x { NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                        }
                        Row {
                            x: 4; y: 4; spacing: 4
                            Repeater {
                                model: root.scales
                                delegate: Item {
                                    required property real modelData
                                    width: 52; height: 30
                                    Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData + "×"
                                           color: Math.abs(modelData - root.pscale) < 0.01 ? Theme.panelBg : Theme.on_surface_variant
                                           font.family: Theme.mono; font.pixelSize: 11; font.bold: true
                                           Behavior on color { ColorAnimation { duration: 200 } } }
                                    MouseArea { anchors.fill: parent; onClicked: { root.pscale = modelData; root.applied = false } }
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        id: applyBtn
                        implicitWidth: 120; implicitHeight: 40; radius: 20
                        color: root.applied ? Theme.accent2 : Theme.accent
                        scale: aArea.pressed ? 0.94 : (aArea.containsMouse ? 1.04 : 1)
                        layer.enabled: true
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Theme.accent; shadowOpacity: aArea.containsMouse ? 0.7 : 0.4
                                                    shadowBlur: 1.0; shadowVerticalOffset: 4
                                                    Behavior on shadowOpacity { NumberAnimation { duration: 200 } } }
                        Behavior on color { ColorAnimation { duration: 250 } }
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        RowLayout {
                            anchors.centerIn: parent; spacing: 6
                            Icon { name: root.applied ? "check" : "tune"; size: 18; color: Theme.panelBg
                                   Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack } } }
                            Text { textFormat: Text.PlainText; text: root.applied ? "Applied" : "Apply"; color: Theme.panelBg; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
                        }
                        MouseArea {
                            id: aArea; anchors.fill: parent; hoverEnabled: true
                            onClicked: { if (root.mon) { root.apply(root.mon, root.pw, root.ph, root.pr.toFixed(2), root.pscale); root.applied = true } }
                        }
                    }
                }
            }
        }
    }
}
