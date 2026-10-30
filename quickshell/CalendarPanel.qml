import QtQuick
import QtQuick.Layouts

// Month calendar, weather forecast and upcoming events.
Panel {
    id: root
    name: "calendar"
    panelWidth: 400

    property date view: new Date()
    onShownChanged: if (shown) view = new Date()
    readonly property int year: view.getFullYear()
    readonly property int month: view.getMonth()
    readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7   // week starts on Monday
    readonly property int days: new Date(year, month + 1, 0).getDate()
    readonly property date today: new Date()
    function shiftMonth(n) { view = new Date(year, month + n, 1) }

    RowLayout {
        Layout.fillWidth: true
        Text { textFormat: Text.PlainText;
            Layout.fillWidth: true
            text: Qt.formatDate(root.view, "MMMM yyyy")
            color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 16; font.bold: true
        }
        Icon { name: "chevron_left"; MouseArea { anchors.fill: parent; onClicked: root.shiftMonth(-1) } }
        Icon { name: "chevron_right"; MouseArea { anchors.fill: parent; onClicked: root.shiftMonth(1) } }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7; columnSpacing: 0; rowSpacing: 2
        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            delegate: Text { textFormat: Text.PlainText;
                required property string modelData
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 11
            }
        }
        Repeater {
            model: 42
            delegate: Item {
                id: cell
                required property int index
                readonly property int day: index - root.offset + 1
                readonly property bool valid: day >= 1 && day <= root.days
                readonly property bool isToday: valid && day === root.today.getDate()
                    && root.month === root.today.getMonth() && root.year === root.today.getFullYear()
                Layout.fillWidth: true
                implicitHeight: 34
                Rectangle {
                    anchors.centerIn: parent
                    width: 32; height: 32; radius: 16
                    color: Theme.primary
                    opacity: cell.isToday ? 1 : 0
                    scale: cell.isToday ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                }
                Text { textFormat: Text.PlainText;
                    anchors.centerIn: parent
                    visible: cell.valid
                    text: cell.day
                    color: cell.isToday ? Theme.on_primary : Theme.on_surface
                    font.family: "JetBrains Mono"; font.pixelSize: 13
                }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outline_variant; opacity: 0.6 }

    // ---- weather ----
    RowLayout {
        Layout.fillWidth: true
        visible: Weather.temp !== ""
        spacing: 12
        Icon { name: Weather.icon; size: 40; fill: 1; color: Theme.primary }
        ColumnLayout {
            spacing: 0
            Text { textFormat: Text.PlainText; text: Weather.temp; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 24; font.bold: true }
            Text { textFormat: Text.PlainText; text: Weather.desc + (Weather.feelsLike ? ", feels " + Weather.feelsLike : ""); color: Theme.on_surface_variant
                   font.family: "JetBrains Mono"; font.pixelSize: 11 }
        }
        Item { Layout.fillWidth: true }
        Repeater {
            model: Weather.forecast
            delegate: ColumnLayout {
                required property var modelData
                spacing: 0
                Layout.leftMargin: 6
                Text { textFormat: Text.PlainText; Layout.alignment: Qt.AlignHCenter; text: modelData.label; color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                Icon { Layout.alignment: Qt.AlignHCenter; name: modelData.icon; size: 22; color: Theme.on_surface_variant }
                Text { textFormat: Text.PlainText; Layout.alignment: Qt.AlignHCenter; text: modelData.max + " / " + modelData.min; color: Theme.on_surface
                       font.family: "JetBrains Mono"; font.pixelSize: 10 }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.outline_variant; opacity: 0.6 }

    // ---- events ----
    Text { textFormat: Text.PlainText; text: "Upcoming"; color: Theme.on_surface; font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true }
    Text { textFormat: Text.PlainText;
        visible: !Events.configured
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "No calendar source. Put an iCal URL in ~/.config/quickshell-local/calendar-url.txt or an export in calendar.ics."
        color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 11
    }
    Text { textFormat: Text.PlainText;
        visible: Events.configured && Events.upcoming.length === 0
        text: "Nothing in the next 30 days"
        color: Theme.outline; font.family: "JetBrains Mono"; font.pixelSize: 11
    }
    Repeater {
        model: Events.upcoming
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Rectangle { width: 4; height: 28; radius: 2; color: Theme.tertiary }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: modelData.title; elide: Text.ElideRight; color: Theme.on_surface
                       font.family: "JetBrains Mono"; font.pixelSize: 12 }
                Text { textFormat: Text.PlainText; text: Qt.formatDate(modelData.start, "ddd d MMM") + (modelData.allDay ? "" : "  " + Qt.formatTime(modelData.start, "HH:mm"))
                       color: Theme.on_surface_variant; font.family: "JetBrains Mono"; font.pixelSize: 10 }
            }
        }
    }
}
