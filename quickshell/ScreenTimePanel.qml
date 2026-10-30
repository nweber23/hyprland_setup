import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Screen time from the data screentime-daemon records. Day view: totals, the week's bars, the day by hour and
// the top apps. Week view: a heat map of the Monday-Sunday week, hour by hour.
Panel {
    id: root
    name: "screentime"
    panelWidth: 780
    centered: true
    pad: 22

    property string mode: "day"          // "day" | "week"
    property int offset: 0               // days back (day view) or weeks back (week view)
    property var stats: ({ total: 0, avg: 0, prev: 0, hours: [], apps: [], week: [], grid: [], peak: -1 })
    property real grow: 0                // bars and cells grow from 0 after the panel opened
    property real dip: 1                 // brief dip when the data changes
    property real totalShown: 0
    Behavior on totalShown { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

    function dateFor(off) {
        const d = new Date(); d.setDate(d.getDate() - off)
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0")
    }
    function fmt(s) {
        s = Math.round(s)
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
        return h > 0 ? h + "h " + m + "m" : m > 0 ? m + "m" : s + "s"
    }
    function title() {
        if (mode === "day") return offset === 0 ? "Today" : offset === 1 ? "Yesterday" : Qt.formatDate(new Date(dateFor(offset) + "T12:00:00"), "ddd, d MMM")
        const g = stats.grid
        if (!g || g.length < 7) return "This week"
        return Qt.formatDate(new Date(g[0].date + "T12:00:00"), "MMM d") + " - " + Qt.formatDate(new Date(g[6].date + "T12:00:00"), "MMM d")
    }
    function load() { if (!query.running) query.running = true }
    onModeChanged: { offset = 0; load() }
    onOffsetChanged: { dipAnim.restart(); load() }
    onShownChanged: if (shown) { mode = "day"; offset = 0; grow = 0; growAnim.restart(); load() }
    SequentialAnimation { id: growAnim; PauseAnimation { duration: 450 }
        NumberAnimation { target: root; property: "grow"; to: 1; duration: 1000; easing.type: Easing.OutCubic } }
    SequentialAnimation { id: dipAnim; NumberAnimation { target: root; property: "dip"; to: 0.25; duration: 80 }
                                       NumberAnimation { target: root; property: "dip"; to: 1; duration: 380; easing.type: Easing.OutCubic } }
    Timer { interval: 15000; repeat: true; running: root.shown; onTriggered: root.load() }

    Process {
        id: query
        command: ["screentime-query", root.dateFor(root.mode === "week" ? root.offset * 7 : root.offset)]
        stdout: StdioCollector { onStreamFinished: { try { root.stats = JSON.parse(text); root.totalShown = root.stats.total } catch (e) {} } }
    }

    // ================= header =================
    Reveal {
        p: root; index: 0; dy: 8
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            Rectangle {   // switch day <-> week
                implicitWidth: 34; implicitHeight: 34; radius: 10; color: swArea.containsMouse ? Theme.cardHigh : Theme.card
                Behavior on color { ColorAnimation { duration: 150 } }
                Icon { anchors.centerIn: parent; name: root.mode === "day" ? "calendar_view_week" : "today"; size: 18; color: Theme.accent
                       rotation: root.mode === "day" ? 0 : 360; Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutBack } } }
                MouseArea { id: swArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.mode = root.mode === "day" ? "week" : "day" }
            }
            Arrow { act: () => root.offset++; name: "chevron_left" }
            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; textFormat: Text.PlainText; opacity: root.dip
                   text: root.title(); color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
            Arrow { act: () => { if (root.offset > 0) root.offset-- }; name: "chevron_right"; opacity: root.offset > 0 ? 1 : 0.25 }
            Item { implicitWidth: 34 }
        }
    }

    // ================= views (they slide past each other) =================
    Item {
        Layout.fillWidth: true
        implicitHeight: root.mode === "day" ? dayView.implicitHeight : weekView.implicitHeight
        Behavior on implicitHeight { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

        // ---------- day ----------
        ColumnLayout {
            id: dayView
            width: parent.width; spacing: 12
            opacity: root.mode === "day" ? 1 : 0; visible: opacity > 0.01
            x: root.mode === "day" ? 0 : -50
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

            Reveal {
                p: root; index: 1; dy: 12; back: true
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    StatCard { Layout.fillWidth: true; caption: "Daily average"; value: root.fmt(root.stats.avg); sub: "last 7 days" }
                    StatCard { Layout.preferredWidth: 300; implicitHeight: 64; caption: ""; value: root.fmt(root.totalShown); valueSize: 26; valueColor: Theme.accent; opacity: root.dip }
                    StatCard {
                        Layout.fillWidth: true; caption: "vs yesterday"
                        readonly property real diff: root.stats.total - root.stats.prev
                        value: (diff >= 0 ? "↑ " : "↓ ") + root.fmt(Math.abs(diff))
                        valueColor: diff > 0 ? Theme.accent2 : Theme.accent
                    }
                }
            }
            Reveal {
                p: root; index: 2; dy: 12
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    // the last 7 days
                    Rectangle {
                        Layout.preferredWidth: 300; Layout.preferredHeight: 150; radius: 12; color: Theme.card
                        Row {
                            anchors { fill: parent; margins: 14 }
                            spacing: 8
                            Repeater {
                                model: root.stats.week || []
                                delegate: Item {
                                    required property var modelData
                                    required property int index
                                    readonly property real peak: Math.max(3600, ...(root.stats.week || []).map(w => w.total))
                                    width: (parent.width - 6 * 8) / 7; height: parent.height
                                    Rectangle {
                                        anchors { bottom: lbl.top; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
                                        width: parent.width * 0.8; radius: 6
                                        height: Math.max(4, modelData.total / parent.peak * (parent.height - 30) * Math.max(0, Math.min(1, root.grow * 1.4 - index * 0.06)))
                                        color: index === 6 ? Theme.accent : Theme.cardHigh
                                        Behavior on height { enabled: root.grow >= 1; NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                                    }
                                    Text { id: lbl; anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter } textFormat: Text.PlainText
                                           text: Qt.locale("en_US").dayName(new Date(modelData.date + "T12:00:00").getDay(), Locale.ShortFormat)
                                           color: index === 6 ? Theme.on_surface : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 9 }
                                    MouseArea { anchors.fill: parent; onClicked: root.offset = root.offset + (6 - index) }
                                }
                            }
                        }
                    }
                    // the day by hour
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 150; radius: 12; color: Theme.card
                        Row {
                            id: hrow
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14; bottomMargin: 30 }
                            height: parent.height - 44; spacing: 3
                            Repeater {
                                model: 24
                                delegate: Item {
                                    required property int index
                                    readonly property real secs: root.stats.hours && root.stats.hours.length === 24 ? root.stats.hours[index] : 0
                                    readonly property real peak: Math.max(900, ...(root.stats.hours || [0]))
                                    width: (hrow.width - 23 * 3) / 24; height: hrow.height
                                    Rectangle {
                                        anchors.bottom: parent.bottom; width: parent.width; radius: 2
                                        height: (secs > 0 ? Math.max(3, secs / peak * parent.height) : 2) * Math.max(0, Math.min(1, root.grow * 1.6 - index * 0.025))
                                        color: secs > 0 ? Theme.accent : Theme.cardHigh
                                        Behavior on height { enabled: root.grow >= 1; NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }
                        }
                        Row {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
                            Repeater { model: ["00", "06", "12", "18", "24"]
                                delegate: Text { required property string modelData; width: parent.width / 5; textFormat: Text.PlainText; text: modelData
                                                 color: Theme.outline; font.family: Theme.mono; font.pixelSize: 9 } }
                        }
                    }
                }
            }
            Reveal {
                p: root; index: 3; dy: 12
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: apps.implicitHeight + 28; radius: 12; color: Theme.card
                    Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    ColumnLayout {
                        id: apps
                        x: 16; y: 14; width: parent.width - 32; spacing: 12
                        Text { visible: !root.stats.apps || root.stats.apps.length === 0; textFormat: Text.PlainText
                               text: "Nothing recorded yet"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
                        Repeater {
                            model: (root.stats.apps || []).slice(0, 5)
                            delegate: ColumnLayout {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true; spacing: 5; opacity: root.dip
                                RowLayout {
                                    spacing: 10
                                    Image { Layout.preferredWidth: 18; Layout.preferredHeight: 18; sourceSize: Qt.size(36, 36); asynchronous: true
                                            source: Quickshell.iconPath(modelData.name.toLowerCase().replace(/ /g, "-"), true) }
                                    Text { Layout.fillWidth: true; textFormat: Text.PlainText; text: modelData.name; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
                                    Text { textFormat: Text.PlainText; text: root.fmt(modelData.seconds); color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 8; radius: 4; color: Theme.cardHigh
                                    Rectangle {
                                        height: parent.height; radius: 4; color: Theme.accent
                                        width: Math.max(8, parent.width * modelData.seconds / root.stats.apps[0].seconds * Math.max(0, Math.min(1, root.grow * 1.5 - index * 0.12)))
                                        Behavior on width { enabled: root.grow >= 1; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---------- week heat map ----------
        Item {
            id: weekView
            width: parent.width; implicitHeight: 300
            opacity: root.mode === "week" ? 1 : 0; visible: opacity > 0.01
            x: root.mode === "week" ? 0 : 50
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

            Rectangle {
                id: heatCard
                x: 0; width: parent.width - 182; height: 300; radius: 12; color: Theme.card
                readonly property real cellW: (width - 28 - 84 - 23 * 2) / 24
                Column {
                    x: 14; y: 14; spacing: 5
                    Repeater {
                        model: root.stats.grid || []
                        delegate: Row {
                            id: drow
                            required property var modelData
                            required property int index
                            spacing: 0; height: 30
                            Text { width: 84; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText
                                   text: Qt.locale("en_US").dayName(new Date(modelData.date + "T12:00:00").getDay(), Locale.LongFormat)
                                   color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 }
                            Row {
                                spacing: 2
                                Repeater {
                                    model: 24
                                    delegate: Rectangle {
                                        id: heat
                                        required property int index
                                        readonly property real secs: drow.modelData.hours[index]
                                        // cells appear in a diagonal wave
                                        readonly property real a: Math.max(0, Math.min(1, root.grow * 2.2 - (index * 0.025 + drow.index * 0.07)))
                                        width: heatCard.cellW; height: 28; radius: 4
                                        color: secs > 0 ? Qt.alpha(Theme.accent, 0.22 + 0.78 * Math.min(1, secs / 3600)) : Theme.cardHigh
                                        opacity: a * (secs > 0 ? 1 : 0.55); scale: 0.6 + 0.4 * a
                                    }
                                }
                            }
                        }
                    }
                }
                Row {
                    x: 14 + 84; y: parent.height - 24; width: parent.width - 28 - 84
                    Repeater { model: ["00:00", "06:00", "12:00", "18:00", "23:00"]
                        delegate: Text { required property string modelData; width: parent.width / 5; textFormat: Text.PlainText; text: modelData
                                         color: Theme.outline; font.family: Theme.mono; font.pixelSize: 9 } }
                }
            }
            ColumnLayout {
                x: parent.width - 170; width: 170; spacing: 12
                StatCard { Layout.fillWidth: true; implicitHeight: 100; caption: "Daily average"; value: root.fmt(root.stats.avg); valueSize: 20 }
                StatCard { Layout.fillWidth: true; implicitHeight: 100; caption: "Peak hours"; valueSize: 18
                           value: root.stats.peak >= 0 ? String(root.stats.peak).padStart(2, "0") + ":00 - " + String((root.stats.peak + 1) % 24).padStart(2, "0") + ":00" : "—" }
            }
        }
    }
}
