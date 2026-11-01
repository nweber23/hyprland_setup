import Quickshell
import QtQuick
import QtQuick.Layouts

// Notification history with Do-not-disturb and Clear.
Panel {
    id: root
    name: "notifications"
    backdrop: "Particles"
    panelWidth: 420
    centered: false
    fixedH: 560       // the list grows and shrinks; the window keeps one size
    onShownChanged: if (shown) NotifHistory.markRead()

    function ago(ms, tickDate) {      // tickDate only makes the binding re-evaluate every minute
        const s = Math.floor((Date.now() - ms) / 1000)
        return s < 60 ? "now" : s < 3600 ? Math.floor(s / 60) + " min ago" : s < 86400 ? Math.floor(s / 3600) + " h ago" : Math.floor(s / 86400) + " d ago"
    }
    SystemClock { id: tick; precision: SystemClock.Minutes }

    // ---- search and per-app filter: the list shows `rows`, rebuilt whenever the history or a filter changes ----
    property string query: ""
    property string appFilter: ""        // "" = all apps
    property var rows: []                // [{ i (index in the history), app, summary, body, icon, time }]
    property var apps: []                // [{ name, count }]
    function rebuild() {
        const q = query.trim().toLowerCase(), out = [], counts = {}
        for (let i = 0; i < NotifHistory.items.count; i++) {
            const n = NotifHistory.items.get(i)
            counts[n.app] = (counts[n.app] ?? 0) + 1
            if (appFilter !== "" && n.app !== appFilter) continue
            if (q !== "" && !(n.app + " " + n.summary + " " + n.body).toLowerCase().includes(q)) continue
            out.push({ i: i, app: n.app, summary: n.summary, body: n.body, icon: n.icon, time: n.time })
        }
        rows = out
        apps = Object.keys(counts).map(k => ({ name: k, count: counts[k] }))
        if (appFilter !== "" && counts[appFilter] === undefined) appFilter = ""
    }
    onQueryChanged: rebuild()
    onAppFilterChanged: rebuild()
    Component.onCompleted: rebuild()
    Connections { target: NotifHistory.items; function onCountChanged() { root.rebuild() } }
    function mute(app) {
        if (Settings.mutedApps.indexOf(app) < 0) Settings.set("mutedApps", Settings.mutedApps.concat([app]))
    }

    Reveal {
        p: root; index: 0; dy: 8
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            Text { Layout.fillWidth: true; textFormat: Text.PlainText; text: "Notifications"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
            Rectangle {   // do not disturb
                implicitHeight: 30; implicitWidth: dndRow.implicitWidth + 22; radius: 10
                color: Popups.dnd ? Theme.accent : (dArea.containsMouse ? Theme.cardHigh : Theme.card)
                Behavior on color { ColorAnimation { duration: 160 } }
                RowLayout { id: dndRow; anchors.centerIn: parent; spacing: 6
                    Icon { name: Popups.dnd ? "notifications_off" : "notifications_active"; size: 16; color: Popups.dnd ? Theme.panelBg : Theme.on_surface }
                    Text { textFormat: Text.PlainText; text: "Do not disturb"; font.family: Theme.mono; font.pixelSize: 11; font.bold: true; color: Popups.dnd ? Theme.panelBg : Theme.on_surface } }
                MouseArea { id: dArea; anchors.fill: parent; hoverEnabled: true; onClicked: Popups.dnd = !Popups.dnd }
            }
            Rectangle {
                implicitHeight: 30; implicitWidth: clrTxt.implicitWidth + 22; radius: 10; opacity: NotifHistory.items.count > 0 ? 1 : 0.4
                color: cArea.containsMouse ? Theme.cardHigh : Theme.card
                Text { id: clrTxt; anchors.centerIn: parent; textFormat: Text.PlainText; text: "Clear"; font.family: Theme.mono; font.pixelSize: 11; font.bold: true; color: Theme.on_surface }
                MouseArea { id: cArea; anchors.fill: parent; hoverEnabled: true; enabled: NotifHistory.items.count > 0; onClicked: NotifHistory.clear() }
            }
        }
    }

    Reveal {
        p: root; index: 1; dy: 10
        visible: NotifHistory.items.count > 0
        Rectangle {   // search
            Layout.fillWidth: true; implicitHeight: 34; radius: 10; color: Theme.card
            RowLayout { anchors { fill: parent; leftMargin: 10; rightMargin: 10 } spacing: 8
                Icon { name: "search"; size: 17; color: Theme.on_surface_variant }
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true; clip: true
                    color: Theme.on_surface; selectionColor: Theme.primary; font.family: Theme.mono; font.pixelSize: 12
                    onTextChanged: root.query = text
                    Text { visible: searchInput.text === ""; textFormat: Text.PlainText; text: "Search notifications\u2026"; color: Theme.outline; font: searchInput.font }
                }
            }
        }
        Flow {   // per-app filter: click an app to see only its notifications
            Layout.fillWidth: true; spacing: 6; visible: root.apps.length > 1
            Repeater {
                model: [{ name: "", count: NotifHistory.items.count }].concat(root.apps)
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: root.appFilter === modelData.name
                    height: 24; width: fl.implicitWidth + 18; radius: 8
                    color: on ? Theme.accent : (fm.containsMouse ? Theme.cardHigh : Theme.card)
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Text { id: fl; anchors.centerIn: parent; textFormat: Text.PlainText; text: (modelData.name === "" ? "All" : modelData.name) + " " + modelData.count
                           color: parent.on ? Theme.panelBg : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10; font.bold: true }
                    MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; onClicked: root.appFilter = modelData.name }
                }
            }
        }
    }

    Reveal {
        p: root; index: 2; dy: 12
        Text { visible: NotifHistory.items.count === 0 || (NotifHistory.items.count > 0 && root.rows.length === 0); Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 24; Layout.bottomMargin: 24; textFormat: Text.PlainText
               text: NotifHistory.items.count === 0 ? "No notifications" : "Nothing matches"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
        ListView {
            id: list
            visible: NotifHistory.items.count > 0
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 360)
            clip: true; spacing: 8; model: root.rows
            boundsBehavior: Flickable.StopAtBounds
            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 } }
            remove: Transition { ParallelAnimation { NumberAnimation { property: "opacity"; to: 0; duration: 180 } NumberAnimation { property: "x"; to: 60; duration: 220; easing.type: Easing.InCubic } } }
            displaced: Transition { NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic } }
            delegate: Item {
                id: slot
                required property int index
                required property var modelData
                width: ListView.view.width; height: card.implicitHeight
                NotifCard {
                    id: card
                    width: parent.width; p: root
                    row: slot.index; app: slot.modelData.app; summary: slot.modelData.summary; body: slot.modelData.body; icon: slot.modelData.icon; time: slot.modelData.time
                    ago: root.ago(slot.modelData.time, tick.date)
                    onRemoveRequested: NotifHistory.remove(slot.modelData.i)
                    onMuteRequested: root.mute(slot.modelData.app)
                }
            }
        }
    }
}
