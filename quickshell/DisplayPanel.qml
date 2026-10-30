import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Resolution, refresh rate and scale per monitor. Changes apply at once through `hyprctl eval` and are
// saved to ~/.config/hypr/monitors-local.{json,lua}; hyprland.lua loads the .lua file after its own rules.
Panel {
    id: root
    name: "display"
    panelWidth: 400

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

    Timer { id: reload; interval: 700; onTriggered: root.load() }   // give Hyprland a moment to apply
    function load() { if (!q.running) q.running = true }
    onShownChanged: if (shown) load()

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

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool active: false
        signal picked()
        implicitHeight: 30; implicitWidth: t.implicitWidth + 22; radius: 15
        color: active ? Theme.primary_container : Theme.surface_container_high
        Behavior on color { ColorAnimation { duration: 160 } }
        Text { id: t; anchors.centerIn: parent; textFormat: Text.PlainText; text: pill.label
               color: pill.active ? Theme.on_primary_container : Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 11 }
        MouseArea { anchors.fill: parent; onClicked: pill.picked() }
    }

    Repeater {
        model: root.monitors
        delegate: ColumnLayout {
            id: mon
            required property var modelData
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Icon { name: "monitor"; size: 20; color: Theme.primary }
                Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                       text: mon.modelData.name + "  ·  " + mon.modelData.description
                       color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true }
            }
            Text { textFormat: Text.PlainText; text: "Resolution"; color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 10 }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: root.resolutions(mon.modelData)
                    delegate: Pill {
                        required property var modelData
                        label: modelData.w + "×" + modelData.h
                        active: modelData.w === mon.modelData.width && modelData.h === mon.modelData.height
                        onPicked: {
                            // keep the current refresh rate if the new size offers it, else take its best one
                            const rs = mon.modelData.modes.filter(m => m.w === modelData.w && m.h === modelData.h)
                            const same = rs.find(m => Math.abs(m.r - mon.modelData.rate) < 1)
                            const pick = same || rs.reduce((a, b) => b.r > a.r ? b : a)
                            root.apply(mon.modelData, pick.w, pick.h, pick.r, mon.modelData.scale)
                        }
                    }
                }
            }
            Text { textFormat: Text.PlainText; text: "Refresh rate"; color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 10 }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: root.ratesFor(mon.modelData)
                    delegate: Pill {
                        required property var modelData
                        label: modelData.r.toFixed(modelData.r % 1 < 0.05 ? 0 : 2) + " Hz"
                        active: Math.abs(modelData.r - mon.modelData.rate) < 0.1
                        onPicked: root.apply(mon.modelData, modelData.w, modelData.h, modelData.r, mon.modelData.scale)
                    }
                }
            }
            Text { textFormat: Text.PlainText; text: "Scale"; color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 10 }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: root.scales
                    delegate: Pill {
                        required property real modelData
                        label: modelData + "×"
                        active: Math.abs(modelData - mon.modelData.scale) < 0.01
                        onPicked: {
                            const m = mon.modelData
                            root.apply(m, m.width, m.height, m.rate.toFixed(2), modelData)
                        }
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; height: 1; color: Theme.outline_variant; opacity: 0.6
                        visible: mon.modelData.name !== root.monitors[root.monitors.length - 1].name }
        }
    }
}
