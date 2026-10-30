import Quickshell
import QtQuick
import QtQuick.Layouts

// Timer / pomodoro, stopwatch, notes and a calculator. The state lives in Tools, so a timer keeps running when the panel is closed.
Panel {
    id: root
    name: "tools"
    backdrop: "Gears"
    panelWidth: 400
    fixedH: 430
    animateHeight: false

    property int tab: 0
    readonly property var tabs: [{ icon: "timer", label: "Timer" }, { icon: "avg_pace", label: "Stopwatch" }, { icon: "edit_note", label: "Notes" }, { icon: "calculate", label: "Calc" }]

    Reveal {
        p: root; index: 0; dy: 8
        RowLayout {   // tabs
            Layout.fillWidth: true; spacing: 6
            Repeater {
                model: root.tabs
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true; implicitHeight: 38; radius: 12
                    color: root.tab === index ? Theme.accent : (tm.containsMouse ? Theme.cardHigh : Theme.card)
                    Behavior on color { ColorAnimation { duration: 160 } }
                    RowLayout {
                        anchors.centerIn: parent; spacing: 5
                        Icon { name: modelData.icon; size: 17; color: root.tab === index ? Theme.panelBg : Theme.on_surface_variant }
                        Text { textFormat: Text.PlainText; text: modelData.label; color: root.tab === index ? Theme.panelBg : Theme.on_surface
                               font.family: Theme.mono; font.pixelSize: 10; font.bold: true }
                    }
                    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; onClicked: root.tab = index }
                }
            }
        }
    }

    Reveal {
        p: root; index: 1; dy: 10
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 340

            // ---------- timer ----------
            ColumnLayout {
                anchors.fill: parent; spacing: 14
                visible: root.tab === 0
                Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText
                       text: Tools.pomodoro ? (Tools.phase === "focus" ? "Focus" : "Break") + "  ·  " + Tools.cycles + " done" : "Countdown"
                       color: Tools.pomodoro && Tools.phase === "break" ? Theme.accent2 : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
                Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: Tools.fmt(Tools.left)
                       color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 76; font.bold: true }
                Rectangle {   // progress
                    Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: Theme.card
                    Rectangle { width: parent.width * (Tools.total > 0 ? Tools.left / Tools.total : 0); height: parent.height; radius: 3; color: Theme.accent
                                Behavior on width { enabled: !Tools.running; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } } }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 14
                    ToolRound { icon: "restart_alt"; onClicked: Tools.reset() }
                    ToolRound { accent: true; icon: Tools.running ? "pause" : "play_arrow"; implicitWidth: 72; implicitHeight: 72; radius: 36; onClicked: Tools.toggle() }
                    ToolRound { icon: "add"; onClicked: if (!Tools.running) { Tools.setTotal(Tools.total + 60) } }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 6
                    Repeater {
                        model: [{ l: "1 min", s: 60 }, { l: "5 min", s: 300 }, { l: "10 min", s: 600 }, { l: "25 min", s: 1500 }]
                        delegate: ToolChip { required property var modelData; label: modelData.l; on: !Tools.pomodoro && Tools.total === modelData.s; onClicked: Tools.setTotal(modelData.s) }
                    }
                    ToolChip { label: "Pomodoro"; on: Tools.pomodoro; onClicked: Tools.togglePomodoro() }
                }
                Item { Layout.fillHeight: true }
            }

            // ---------- stopwatch ----------
            ColumnLayout {
                anchors.fill: parent; spacing: 14
                visible: root.tab === 1
                Item { Layout.preferredHeight: 6 }
                Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: Tools.swFmt(Tools.swMs)
                       color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 60; font.bold: true }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 14
                    ToolRound { icon: "restart_alt"; onClicked: Tools.swReset() }
                    ToolRound { accent: true; icon: Tools.swRunning ? "pause" : "play_arrow"; implicitWidth: 72; implicitHeight: 72; radius: 36; onClicked: Tools.swToggle() }
                    ToolRound { icon: "flag"; onClicked: Tools.swLap() }
                }
                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    model: Tools.laps
                    delegate: RowLayout {
                        required property int index
                        required property real modelData
                        width: ListView.view.width; height: 26
                        Text { textFormat: Text.PlainText; text: "Lap " + (Tools.laps.length - index); color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                        Text { textFormat: Text.PlainText; text: Tools.swFmt(modelData); color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12 }
                    }
                }
            }

            // ---------- notes ----------
            Rectangle {
                anchors.fill: parent; visible: root.tab === 2
                radius: 14; color: Theme.card
                Flickable {
                    anchors { fill: parent; margins: 12 }
                    contentWidth: width; contentHeight: notes.implicitHeight; clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    TextEdit {
                        id: notes
                        width: parent.width; wrapMode: TextEdit.Wrap; textFormat: TextEdit.PlainText
                        color: Theme.on_surface; selectionColor: Theme.primary; font.family: Theme.mono; font.pixelSize: 13
                        text: Tools.notes
                        onTextChanged: if (activeFocus) save.restart()
                        Timer { id: save; interval: 500; onTriggered: Tools.saveNotes(notes.text) }
                        Text { visible: notes.text === ""; textFormat: Text.PlainText; text: "Write something down. It is saved as you type."; color: Theme.outline; font: notes.font }
                    }
                }
            }

            // ---------- calculator ----------
            ColumnLayout {
                id: calcView
                anchors.fill: parent; spacing: 12
                visible: root.tab === 3
                property var history: []
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 96; radius: 14; color: Theme.card
                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 2
                        TextInput {
                            id: expr
                            Layout.fillWidth: true
                            color: Theme.on_surface; selectionColor: Theme.primary; font.family: Theme.mono; font.pixelSize: 18; clip: true
                            onAccepted: { const r = Tools.calc(text); if (r !== null) { calcView.history = [{ e: text, r: r }].concat(calcView.history).slice(0, 8); text = r } }
                            Text { visible: expr.text === ""; textFormat: Text.PlainText; text: "12 * (3 + 4)"; color: Theme.outline; font: expr.font }
                        }
                        Text { Layout.alignment: Qt.AlignRight; textFormat: Text.PlainText
                               text: { const r = Tools.calc(expr.text); return r === null ? "" : "= " + r }
                               color: Theme.accent; font.family: Theme.mono; font.pixelSize: 28; font.bold: true }
                    }
                }
                Text { textFormat: Text.PlainText; text: "Enter keeps the result, click a line to copy it"; color: Theme.outline; font.family: Theme.mono; font.pixelSize: 10 }
                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    model: calcView.history
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width; height: 32; radius: 10
                        color: hm.containsMouse ? Theme.cardHigh : "transparent"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: modelData.e; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
                            Text { textFormat: Text.PlainText; text: "= " + modelData.r; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
                        }
                        MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true
                                    onClicked: Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", modelData.r]) }
                    }
                }
            }
        }
    }

    onShownChanged: if (shown && tab === 3) expr.forceActiveFocus()
    onTabChanged: if (tab === 3) expr.forceActiveFocus()
}
