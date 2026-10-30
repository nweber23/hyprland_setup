import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// Calendar, clock, weather and upcoming events (layout and motion after the original):
//   left   month grid        centre  big clock inside an orbit of 3-hourly forecasts      right  weather of the chosen day
//   bottom next events on soft waves
Panel {
    id: root
    name: "calendar"
    panelWidth: 1080
    centered: true
    pad: 22

    // ---- state ----
    property date viewMonth: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    property int monthTick: 0              // bumps on every month change so the day cells re-animate
    property int weatherView: 0            // 0 today, 1 tomorrow, 2 day after
    readonly property var day: Weather.days.length > weatherView ? Weather.days[weatherView] : null
    readonly property bool isToday: weatherView === 0
    property real spin: 0                  // extra orbit angle while switching days
    property real orbitAngle: 0
    property real osc: 0
    SystemClock { id: clock; precision: SystemClock.Seconds }

    function shiftMonth(d) { viewMonth = new Date(viewMonth.getFullYear(), viewMonth.getMonth() + d, 1); monthTick++ }
    function shiftDay(d) {
        const n = Math.max(0, Math.min(Weather.days.length - 1, weatherView + d)); if (n === weatherView) return
        weatherView = n; spinAnim.restart(); tempFlash.restart()
    }
    NumberAnimation { id: spinAnim; target: root; property: "spin"; from: 140; to: 0; duration: 800; easing.type: Easing.OutCubic }
    // the orbit of the other days turns once a minute, today's slots only sway a little
    NumberAnimation on orbitAngle { from: 0; to: -360; duration: 60000; loops: Animation.Infinite; running: root.shown }
    NumberAnimation on osc { from: 0; to: Math.PI * 2; duration: 9000; loops: Animation.Infinite; running: root.shown }
    // gauge values: right now for today, the day's own values for the others
    readonly property real gWind: isToday || !day || day.wind === undefined ? Weather.wind : day.wind
    readonly property real gHumid: isToday || !day || day.humidity === undefined ? Weather.humidity : day.humidity
    readonly property real gRain: isToday || !day || day.rain === undefined ? Weather.rain : day.rain
    readonly property real gFeels: isToday || !day || day.feels === undefined ? Weather.feelsNum : day.feels
    readonly property int activeSlot: Math.min(7, Math.floor(clock.date.getHours() / 3))

    // the big temperature counts to its value, the gauges sweep
    property real tempShown: isToday ? Weather.tempNum : (day ? day.max : 0)
    Behavior on tempShown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    property real tempFlashV: 1
    SequentialAnimation { id: tempFlash; NumberAnimation { target: root; property: "tempFlashV"; to: 0.2; duration: 90 }
                                         NumberAnimation { target: root; property: "tempFlashV"; to: 1; duration: 420; easing.type: Easing.OutCubic } }

    RowLayout {
        Layout.fillWidth: true
        spacing: 18

        // ================= month =================
        Reveal {
            p: root; index: 2; dx: -24; dy: 6; easing_: Easing.OutQuint; Layout.fillWidth: false
            Rectangle {
                Layout.preferredWidth: 270; Layout.preferredHeight: 376; radius: 12; color: Theme.card
                ColumnLayout {
                    x: 14; y: 14; width: parent.width - 28; spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        Arrow { act: () => root.shiftMonth(-1); name: "chevron_left" }
                        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; textFormat: Text.PlainText
                               text: Qt.formatDate(root.viewMonth, "MMMM yyyy").toUpperCase()
                               color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
                        Arrow { act: () => root.shiftMonth(1); name: "chevron_right" }
                    }
                    Row {
                        Layout.fillWidth: true
                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                            delegate: Text { required property string modelData; width: 34; horizontalAlignment: Text.AlignHCenter
                                             textFormat: Text.PlainText; text: modelData; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10; font.bold: true }
                        }
                    }
                    GridLayout {
                        columns: 7; rowSpacing: 4; columnSpacing: 0
                        Repeater {
                            model: 42
                            delegate: Item {
                                id: cell
                                required property int index
                                readonly property date d: {
                                    const first = new Date(root.viewMonth.getFullYear(), root.viewMonth.getMonth(), 1)
                                    return new Date(first.getFullYear(), first.getMonth(), 1 - (first.getDay() + 6) % 7 + index)
                                }
                                readonly property bool inMonth: d.getMonth() === root.viewMonth.getMonth()
                                readonly property bool today: d.toDateString() === new Date().toDateString()
                                property real a: 1
                                Layout.preferredWidth: 34; Layout.preferredHeight: 34
                                opacity: a * (inMonth ? 1 : 0.22); scale: 0.7 + 0.3 * a
                                Connections { target: root; function onMonthTickChanged() { re.restart() } }
                                SequentialAnimation { id: re
                                    ScriptAction { script: cell.a = 0 }
                                    PauseAnimation { duration: cell.index * 9 }
                                    NumberAnimation { target: cell; property: "a"; to: 1; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                                Rectangle {
                                    anchors.centerIn: parent; width: 30; height: 30; radius: 9
                                    color: cell.today ? Theme.accent : (dayArea.containsMouse ? Theme.cardHigh : "transparent")
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: cell.d.getDate()
                                           color: cell.today ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12; font.bold: cell.today }
                                }
                                MouseArea { id: dayArea; anchors.fill: parent; hoverEnabled: true }
                            }
                        }
                    }
                }
            }
        }

        // ================= clock + orbit =================
        Reveal {
            p: root; index: 0; dy: 0; back: true; duration_: 900
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 376
                id: stage
                readonly property real cx: width / 2
                readonly property real cy: height * 0.5

                // dashed ellipse, slowly crawling
                Shape {
                    id: orbit
                    anchors.fill: parent; layer.enabled: true; layer.samples: 4
                    property real off: 0
                    NumberAnimation on off { from: 0; to: -16; duration: 3200; loops: Animation.Infinite; running: root.shown }
                    ShapePath {
                        strokeColor: Qt.alpha(Theme.on_surface, 0.22); strokeWidth: 1.2; fillColor: "transparent"
                        strokeStyle: ShapePath.DashLine; dashPattern: [4, 6]; dashOffset: orbit.off
                        PathAngleArc { centerX: stage.cx; centerY: stage.cy; radiusX: 218; radiusY: 112; startAngle: 0; sweepAngle: 360 }
                    }
                }

                Column {
                    anchors.centerIn: parent; anchors.verticalCenterOffset: -stage.height * 0.03; spacing: 2
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                        Text { anchors.baseline: sec.baseline; textFormat: Text.PlainText; text: Qt.formatTime(clock.date, "HH:mm")
                               color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 58; font.bold: true }
                        Text { id: sec; textFormat: Text.PlainText; text: ":" + Qt.formatTime(clock.date, "ss")
                               color: Theme.accent; font.family: Theme.mono; font.pixelSize: 26; font.bold: true }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; textFormat: Text.PlainText
                           text: Qt.formatDate(clock.date, "dddd, MMMM d"); color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 13 }
                }

                // forecast slots on the ellipse; the ones lower on the ellipse are nearer: bigger and more opaque
                Repeater {
                    model: root.day ? root.day.hourly : []
                    delegate: Rectangle {
                        id: slot
                        required property var modelData
                        required property int index
                        readonly property bool active: root.isToday && index === root.activeSlot
                        readonly property int rel: root.isToday ? index - root.activeSlot : index
                        readonly property real ang: root.isToday ? 65 + rel * 30 + Math.sin(root.osc + index) * 2.5 + root.spin
                                                                 : index * 45 + root.orbitAngle + root.spin
                        readonly property real rad: ang * Math.PI / 180
                        readonly property real depth: (Math.sin(rad) + 1) / 2
                        width: 52; height: 80; radius: 14
                        x: stage.cx + Math.cos(rad) * 218 - width / 2
                        y: stage.cy + Math.sin(rad) * 112 - height / 2
                        z: Math.sin(rad) * 100 + (active ? 10 : 0)
                        scale: active ? 0.8 + 0.55 * depth : 0.66 + 0.42 * depth
                        opacity: (active ? 0.78 + 0.22 * depth : 0.5 + 0.5 * depth) * root.tempFlashV
                        color: active ? Theme.accent2 : Qt.alpha(Theme.card, 0.9)
                        Behavior on color { ColorAnimation { duration: 300 } }
                        Column {
                            anchors.centerIn: parent; spacing: 3
                            Text { anchors.horizontalCenter: parent.horizontalCenter; textFormat: Text.PlainText; text: slot.modelData.label
                                   color: slot.active ? Theme.panelBg : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 9 }
                            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: slot.modelData.icon; size: 24; color: slot.active ? Theme.panelBg : Theme.on_surface }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; textFormat: Text.PlainText; text: slot.modelData.temp
                                   color: slot.active ? Theme.panelBg : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11; font.bold: true }
                        }
                    }
                }
            }
        }

        // ================= weather =================
        Reveal {
            p: root; index: 3; dx: 24; dy: 6; easing_: Easing.OutQuint; Layout.fillWidth: false
            ColumnLayout {
                Layout.preferredWidth: 260; spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    Arrow { act: () => root.shiftDay(-1); name: "chevron_left"; opacity: root.weatherView > 0 ? 1 : 0.25 }
                    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; textFormat: Text.PlainText
                           text: !root.day ? "—" : root.isToday ? Qt.formatDate(clock.date, "dddd").toUpperCase()
                         : (root.day.date ? Qt.formatDate(new Date(root.day.date + "T12:00:00"), "ddd d MMM") : root.day.name).toUpperCase()
                           color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
                    Arrow { act: () => root.shiftDay(1); name: "chevron_right"; opacity: root.weatherView < Weather.days.length - 1 ? 1 : 0.25 }
                }
                Text { Layout.alignment: Qt.AlignRight; textFormat: Text.PlainText; opacity: root.tempFlashV
                       text: Math.round(root.tempShown) + "°"; color: Theme.accent2
                       font.family: Theme.mono; font.pixelSize: 84; font.bold: true }
                Text { Layout.alignment: Qt.AlignRight; textFormat: Text.PlainText; opacity: root.tempFlashV
                       text: root.day ? (root.isToday ? Weather.desc : root.day.desc) : ""; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 13 }
                Item { Layout.fillHeight: true; Layout.preferredHeight: 60 }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Repeater {
                        model: [
                            { v: root.gWind / 40, t: Math.round(root.gWind) + "", l: "WIND", i: "air" },
                            { v: root.gHumid / 100, t: Math.round(root.gHumid) + "%", l: "HUMID", i: "water_drop" },
                            { v: root.gRain / 100, t: Math.round(root.gRain) + "%", l: "RAIN", i: "umbrella" },
                            { v: (root.gFeels + 10) / 45, t: Math.round(root.gFeels) + "°", l: "FEELS", i: "thermostat" }
                        ]
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true; spacing: 4
                            Item {
                                Layout.alignment: Qt.AlignHCenter; implicitWidth: 56; implicitHeight: 56
                                Gauge { anchors.fill: parent; value: root.shown ? modelData.v : 0; thickness: 4; color: Theme.accent
                                        Behavior on value { NumberAnimation { duration: 1100; easing.type: Easing.OutCubic } } }
                                Text { x: Math.round((parent.width - width) / 2); y: Math.round((parent.height - height) / 2)
                                       renderType: Text.NativeRendering; textFormat: Text.PlainText; text: modelData.t; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 11; font.bold: true }
                            }
                            RowLayout { Layout.alignment: Qt.AlignHCenter; spacing: 3
                                Icon { name: modelData.i; size: 11; color: Theme.on_surface_variant }
                                Text { renderType: Text.NativeRendering; textFormat: Text.PlainText; text: modelData.l; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 9 } }
                        }
                    }
                }
            }
        }
    }

    // ================= events =================
    Reveal {
        p: root; index: 4; dy: 14; easing_: Easing.OutQuint
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardHigh }
        RowLayout {
            Layout.fillWidth: true; Layout.topMargin: 4; spacing: 12
            Rectangle { implicitWidth: 34; implicitHeight: 34; radius: 17; color: Theme.card
                        Icon { anchors.centerIn: parent; name: "calendar_month"; size: 18; color: Theme.accent } }
            Text { Layout.fillWidth: true; textFormat: Text.PlainText
                   text: Events.upcoming.length > 0 ? Qt.formatDate(Events.upcoming[0].start, "dddd, dd MMM") + " (Upcoming)" : (Events.configured ? "No upcoming events" : "No calendar source")
                   color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 14; font.bold: true }
            Rectangle {
                implicitWidth: ow.implicitWidth + 28; implicitHeight: 32; radius: 10; color: owArea.containsMouse ? Theme.cardHigh : "transparent"
                border.width: 1; border.color: Theme.accent
                Behavior on color { ColorAnimation { duration: 150 } }
                RowLayout { id: ow; anchors.centerIn: parent; spacing: 6
                    Text { textFormat: Text.PlainText; text: "Open Web"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12; font.bold: true }
                    Icon { name: "open_in_new"; size: 14; color: Theme.accent } }
                MouseArea { id: owArea; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["xdg-open", "https://calendar.google.com"]) }
            }
        }
        Item {
            Layout.fillWidth: true; implicitHeight: 96
            // two soft waves drifting behind the cards
            Canvas {
                id: waves
                anchors.fill: parent
                property real phase: 0
                NumberAnimation on phase { from: 0; to: Math.PI * 2; duration: 7000; loops: Animation.Infinite; running: root.shown }
                onPhaseChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d"); c.reset()
                    for (let k = 0; k < 2; k++) {
                        c.beginPath()
                        for (let x = 0; x <= width; x += 6) {
                            const y = height * 0.5 + Math.sin(x / 110 + phase * (k ? -1 : 1) + k) * (10 + k * 6)
                            if (x === 0) c.moveTo(x, y); else c.lineTo(x, y)
                        }
                        c.strokeStyle = Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10)
                        c.lineWidth = 1.4; c.stroke()
                    }
                }
            }
            RowLayout {
                anchors.fill: parent; spacing: 0
                Repeater {
                    // the events of the first upcoming day, as the heading says
                    model: Events.upcoming.filter(e => e.start.toDateString() === Events.upcoming[0].start.toDateString()).slice(0, 3)
                    delegate: Rectangle {
                        id: ev
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: "transparent"
                        Rectangle { width: 2; height: parent.height - 16; y: 8; radius: 1; color: Theme.cardHigh }
                        ColumnLayout {
                            anchors { fill: parent; leftMargin: 16; topMargin: 8 }
                            spacing: 5
                            Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight; text: ev.modelData.title
                                   color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 14; font.bold: true }
                            RowLayout { spacing: 6
                                Icon { name: "schedule"; size: 14; color: Theme.accent }
                                Text { textFormat: Text.PlainText
                                       text: ev.modelData.allDay ? "All day" : Qt.formatTime(ev.modelData.start, "hh:mm") + (ev.modelData.end ? "-" + Qt.formatTime(ev.modelData.end, "hh:mm") : "")
                                       color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12 } }
                            RowLayout { spacing: 6; visible: (ev.modelData.location ?? "") !== ""
                                Icon { name: "location_on"; size: 14; color: Theme.accent }
                                Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight; text: ev.modelData.location ?? ""
                                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 } }
                        }
                    }
                }
                Text { visible: Events.upcoming.length === 0; Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 16; textFormat: Text.PlainText
                       text: Events.configured ? "Nothing planned for the next 30 days." : "Put your calendar's iCal link in ~/.config/quickshell-local/calendar-url.txt"
                       color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
                Item { Layout.fillWidth: true; visible: Events.upcoming.length === 0 }
            }
        }
    }
}
