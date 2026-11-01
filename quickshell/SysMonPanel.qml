import QtQuick
import QtQuick.Layouts

// System monitor: four rings that count up, two charts that glide, and the busiest processes.
Panel {
    id: root
    name: "sysmon"
    backdrop: "Grid"
    panelWidth: 640
    centered: false
    fixedH: 640
    onShownChanged: SysMon.active = shown

    function fmtRate(b) { return b > 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : b > 1024 ? (b / 1024).toFixed(0) + " kB/s" : Math.round(b) + " B/s" }
    function fmtUp(s) { const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60); return (d > 0 ? d + "d " : "") + h + "h " + m + "m" }
    // numbers glide to their new value
    property real cpuS: SysMon.cpu;  Behavior on cpuS { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    property real memS: SysMon.mem;  Behavior on memS { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    property real tmpS: SysMon.temp; Behavior on tmpS { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    property real dskS: SysMon.disk; Behavior on dskS { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    Reveal {
        p: root; index: 0; dy: 8
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; textFormat: Text.PlainText; text: "System"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
            Icon { name: "schedule"; size: 15; color: Theme.on_surface_variant }
            Text { textFormat: Text.PlainText; text: "up " + root.fmtUp(SysMon.uptime); color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
        }
    }

    Reveal {
        p: root; index: 1; dy: 14; back: true
        RowLayout {
            Layout.fillWidth: true; spacing: 12
            Repeater {
                model: [
                    { l: "CPU", i: "memory", v: root.cpuS / 100, t: Math.round(root.cpuS) + "%", c: Theme.accent },
                    { l: "RAM", i: "developer_board", v: root.memS / 100, t: Math.round(root.memS) + "%", c: Theme.accent2 },
                    { l: "TEMP", i: "device_thermostat", v: Math.max(0, root.tmpS - 30) / 70, t: Math.round(root.tmpS) + "°", c: root.tmpS > 80 ? Theme.error : Theme.accent },
                    { l: "DISK", i: "hard_drive", v: root.dskS / 100, t: Math.round(root.dskS) + "%", c: Theme.accent2 }
                ]
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true; spacing: 6
                    Item {
                        Layout.alignment: Qt.AlignHCenter; implicitWidth: 104; implicitHeight: 104
                        Gauge { anchors.fill: parent; value: root.shown ? modelData.v : 0; thickness: 9; color: modelData.c
                                Behavior on value { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } } }
                        Text { x: Math.round((parent.width - width) / 2); y: Math.round((parent.height - height) / 2 - 2); renderType: Text.NativeRendering
                               textFormat: Text.PlainText; text: modelData.t; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 20; font.bold: true }
                    }
                    RowLayout { Layout.alignment: Qt.AlignHCenter; spacing: 4
                        Icon { name: modelData.i; size: 14; color: Theme.on_surface_variant }
                        Text { textFormat: Text.PlainText; text: modelData.l; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10; font.bold: true } }
                }
            }
        }
    }

    Reveal {   // temperatures; this laptop reports no fan speed
        p: root; index: 2; dy: 14
        RowLayout {
            Layout.fillWidth: true; spacing: 12
            StatCard { Layout.fillWidth: true; caption: "CPU"; value: Math.round(SysMon.temp) + " \u00b0C"; valueColor: SysMon.temp >= 85 ? Theme.error : Theme.on_surface }
            StatCard { Layout.fillWidth: true; caption: "GPU"; value: Math.round(SysMon.gpuTemp) + " \u00b0C"; valueColor: SysMon.gpuTemp >= 85 ? Theme.error : Theme.on_surface }
            StatCard { Layout.fillWidth: true; caption: "SSD"; value: Math.round(SysMon.ssdTemp) + " \u00b0C"; valueColor: SysMon.ssdTemp >= 70 ? Theme.error : Theme.on_surface }
            StatCard { Layout.fillWidth: true; caption: "FAN"; value: "n/a"; sub: "not reported" }
        }
    }

    Reveal {
        p: root; index: 3; dy: 14
        RowLayout {
            Layout.fillWidth: true; spacing: 12
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 120; radius: 12; color: Theme.card; clip: true
                Sparkline { anchors { fill: parent; topMargin: 28 } values: SysMon.cpuHist; tick: SysMon.tick; maxValue: 100; tone: Theme.accent }
                Text { x: 12; y: 8; textFormat: Text.PlainText; text: "CPU  " + SysMon.memUsedGb.toFixed(1) + " / " + SysMon.memTotalGb.toFixed(1) + " GB RAM"
                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 120; radius: 12; color: Theme.card; clip: true
                Sparkline { anchors { fill: parent; topMargin: 28 } values: SysMon.netHist; tick: SysMon.tick; maxValue: Math.max(200000, ...SysMon.netHist); tone: Theme.accent2 }
                Text { x: 12; y: 8; textFormat: Text.PlainText; text: "NET  ↓ " + root.fmtRate(SysMon.down) + "   ↑ " + root.fmtRate(SysMon.up)
                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
            }
        }
    }

    Reveal {
        p: root; index: 4; dy: 14
        Rectangle {
            Layout.fillWidth: true; implicitHeight: procCol.implicitHeight + 28; radius: 12; color: Theme.card
            ColumnLayout {
                id: procCol
                x: 16; y: 14; width: parent.width - 32; spacing: 10
                Text { textFormat: Text.PlainText; text: "Busiest"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
                Repeater {
                    model: SysMon.procs
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true; spacing: 10
                        Text { Layout.preferredWidth: 150; elide: Text.ElideRight; textFormat: Text.PlainText; text: modelData.name; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12 }
                        Rectangle {
                            Layout.fillWidth: true; height: 7; radius: 3.5; color: Theme.cardHigh
                            Rectangle { height: parent.height; radius: 3.5; color: Theme.accent; width: Math.max(7, parent.width * Math.min(1, modelData.cpu / 100))
                                        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } } }
                        }
                        Text { Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight; textFormat: Text.PlainText; text: modelData.cpu.toFixed(1) + "%"
                               color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
                    }
                }
            }
        }
    }
}
