import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Screen time per app, from the data screentime-daemon records. Browse days with the arrows or the week chart.
Panel {
    id: root
    name: "screentime"
    panelWidth: 440

    property int offset: 0   // 0 = today, 1 = yesterday, ...
    property var stats: ({ total: 0, avg: 0, hours: [], apps: [], week: [] })

    function dateFor(off) {
        const d = new Date(); d.setDate(d.getDate() - off)
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0")
    }
    function fmt(s) {
        s = Math.round(s)
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
        return h > 0 ? h + "h " + m + "m" : m > 0 ? m + "m" : s + "s"
    }
    function dayLabel(off) {
        if (off === 0) return "Today"
        if (off === 1) return "Yesterday"
        return Qt.formatDate(new Date(dateFor(off) + "T12:00:00"), "ddd, d MMM")
    }
    function load() { if (!query.running) query.running = true }
    onOffsetChanged: load()
    onShownChanged: if (shown) { offset = 0; load() }
    Timer { interval: 15000; repeat: true; running: root.shown; onTriggered: root.load() }

    Process {
        id: query
        command: ["screentime-query", root.dateFor(root.offset)]
        stdout: StdioCollector { onStreamFinished: { try { root.stats = JSON.parse(text) } catch (e) {} } }
    }

    // ---- day navigation ----
    RowLayout {
        Layout.fillWidth: true
        Icon { name: "chevron_left"; size: 24; MouseArea { anchors.fill: parent; onClicked: root.offset++ } }
        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; textFormat: Text.PlainText
               text: root.dayLabel(root.offset); color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
        Icon { name: "chevron_right"; size: 24; opacity: root.offset > 0 ? 1 : 0.25
               MouseArea { anchors.fill: parent; enabled: root.offset > 0; onClicked: root.offset-- } }
    }

    // ---- total ----
    RowLayout {
        Layout.fillWidth: true
        Text { textFormat: Text.PlainText; text: root.fmt(root.stats.total); color: Theme.primary
               font.family: "JetBrains Mono"; font.pixelSize: 30; font.bold: true }
        Item { Layout.fillWidth: true }
        Text { textFormat: Text.PlainText; visible: root.stats.avg > 0; text: "avg " + root.fmt(root.stats.avg) + " / day"
               color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 11 }
    }

    // ---- hours of the day ----
    Item {
        Layout.fillWidth: true; implicitHeight: 84
        Row {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 64; spacing: 2
            Repeater {
                model: 24
                delegate: Item {
                    required property int index
                    readonly property real secs: root.stats.hours && root.stats.hours.length === 24 ? root.stats.hours[index] : 0
                    readonly property real peak: Math.max(900, ...(root.stats.hours || [0]))   // at least a 15 min scale
                    width: (parent.width - 46) / 24; height: parent.height
                    Rectangle {
                        anchors.bottom: parent.bottom; width: parent.width
                        height: secs > 0 ? Math.max(3, secs / peak * parent.height) : 2
                        radius: 2
                        color: secs > 0 ? Theme.primary : Theme.surface_container_high
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
        RowLayout {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            Repeater {
                model: ["00", "06", "12", "18", "24"]
                delegate: Text { required property string modelData; Layout.fillWidth: true
                                 horizontalAlignment: index === 0 ? Text.AlignLeft : index === 4 ? Text.AlignRight : Text.AlignHCenter
                                 required property int index
                                 textFormat: Text.PlainText; text: modelData; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 9 }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outline_variant; opacity: 0.6 }

    // ---- last 7 days ----
    RowLayout {
        Layout.fillWidth: true; spacing: 6
        Repeater {
            model: root.stats.week || []
            delegate: Item {
                required property var modelData
                required property int index
                readonly property int off: root.offset + (6 - index)   // days back from today
                readonly property real peak: Math.max(3600, ...(root.stats.week || []).map(w => w.total))
                Layout.fillWidth: true; implicitHeight: 70
                Rectangle {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: lbl.top; bottomMargin: 4 }
                    width: 22; height: Math.max(3, modelData.total / peak * 46); radius: 6
                    color: index === 6 ? Theme.primary : Theme.surface_container_high
                    Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                }
                Text { id: lbl; anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                       textFormat: Text.PlainText
                       text: Qt.locale("en_US").dayName(new Date(modelData.date + "T12:00:00").getDay(), Locale.ShortFormat)
                       color: index === 6 ? Theme.on_surface : Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                MouseArea { anchors.fill: parent; onClicked: root.offset = parent.off }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outline_variant; opacity: 0.6 }

    // ---- apps ----
    Text { textFormat: Text.PlainText; visible: !root.stats.apps || root.stats.apps.length === 0
           text: "Nothing recorded yet"; color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 12 }
    Repeater {
        model: (root.stats.apps || []).slice(0, 6)
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true; spacing: 10
            Text { Layout.preferredWidth: 110; elide: Text.ElideRight; textFormat: Text.PlainText; text: modelData.name
                   color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 12 }
            Rectangle {
                Layout.fillWidth: true; height: 8; radius: 4; color: Theme.surface_container_high
                Rectangle {
                    height: parent.height; radius: 4; color: Theme.primary
                    width: Math.max(8, parent.width * modelData.seconds / root.stats.apps[0].seconds)
                    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                }
            }
            Text { Layout.preferredWidth: 56; horizontalAlignment: Text.AlignRight; textFormat: Text.PlainText; text: root.fmt(modelData.seconds)
                   color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 11 }
        }
    }
}
