import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Screenshots and screen recording without needing a Print key: pick what and after how long.
Panel {
    id: root
    name: "capture"
    backdrop: "Viewfinder"
    panelWidth: 420

    property int delay: 0              // seconds before the shot is taken
    readonly property bool recording: Recorder.recording

    // The panel fades out first, so it is not in the picture and slurp can take the pointer.
    function shoot(mode) {
        Popups.close()
        Quickshell.execDetached(["sh", "-c", 'sleep 0.5; sleep "$1"; exec screenshot "$2"', "sh", String(delay), mode])
    }
    function tool(cmd) {   // the panel fades out first so it is not in the picture and slurp can take the pointer
        Popups.close()
        Quickshell.execDetached(["sh", "-c", 'sleep 0.5; exec "$1"', "sh", cmd])
    }
    function record(mode) {
        Popups.close()
        Quickshell.execDetached(["sh", "-c", 'sleep 0.4; exec record "$1"', "sh", mode])
    }

    Reveal {
        p: root; index: 0; dy: 8
        Text { textFormat: Text.PlainText; text: "Screenshot"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            CaptureTile { icon: "crop"; label: "Region"; onActivated: root.shoot("region") }
            CaptureTile { icon: "desktop_windows"; label: "Full screen"; onActivated: root.shoot("full") }
            CaptureTile { icon: "web_asset"; label: "Window"; onActivated: root.shoot("window") }
            CaptureTile { icon: "draw"; label: "Annotate"; onActivated: root.shoot("annotate") }
        }
        // delay before the shot: lets you open a menu first
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { textFormat: Text.PlainText; text: "Delay"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
            Item { Layout.fillWidth: true }
            Rectangle {
                implicitWidth: 4 * 54 + 3 * 4 + 8; implicitHeight: 34; radius: 11; color: Theme.card
                Rectangle {
                    width: 54; height: 26; radius: 8; color: Theme.accent; y: 4
                    x: 4 + [0, 3, 5, 10].indexOf(root.delay) * 58
                    Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                }
                Row {
                    x: 4; y: 4; spacing: 4
                    Repeater {
                        model: [0, 3, 5, 10]
                        delegate: Item {
                            required property int modelData
                            width: 54; height: 26
                            Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData === 0 ? "none" : modelData + " s"
                                   color: root.delay === modelData ? Theme.panelBg : Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11; font.bold: true
                                   Behavior on color { ColorAnimation { duration: 200 } } }
                            MouseArea { anchors.fill: parent; onClicked: root.delay = modelData }
                        }
                    }
                }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardHigh }

    Reveal {
        p: root; index: 1; dy: 10
        Text { textFormat: Text.PlainText; text: "From the screen"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            CaptureTile { icon: "text_fields"; label: "Copy text"; onActivated: root.tool("screen-ocr") }
            CaptureTile { icon: "qr_code_scanner"; label: "QR code"; onActivated: root.tool("screen-qr") }
            CaptureTile { icon: "colorize"; label: "Pick colour"; onActivated: root.tool("colorpick") }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardHigh }

    Reveal {
        p: root; index: 2; dy: 10
        Text { textFormat: Text.PlainText; text: "Screen recording"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; font.bold: true }
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            CaptureTile { visible: root.recording; icon: "stop_circle"; label: "Stop recording"; danger: true; onActivated: root.record("full") }
            CaptureTile { visible: !root.recording; icon: "fiber_manual_record"; tone: Theme.error; label: "Record region"; onActivated: root.record("region") }
            CaptureTile { visible: !root.recording; icon: "screen_record"; tone: Theme.error; label: "Record screen"; onActivated: root.record("full") }
            CaptureTile { icon: "folder_open"; label: "Open folder"
                          onActivated: { Popups.close(); Quickshell.execDetached(["sh", "-c", 'mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Videos"; xdg-open "$HOME/Pictures/Screenshots"']) } }
        }
    }
}
