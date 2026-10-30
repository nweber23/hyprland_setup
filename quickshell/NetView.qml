import QtQuick

// One radial view: two nodes joined by a link, each with three info chips on dashed lines.
//   leftNode / rightNode = { tone, icon, title, status, online, chips: [{ icon, value, label }] }
Item {
    id: v
    property var leftNode: ({})
    property var rightNode: ({})
    property bool shown: false
    readonly property real lx: width * 0.29
    readonly property real ly: height * 0.46
    readonly property real rx: width * 0.71
    readonly property real ry: height * 0.52
    readonly property var lOff: [[-6, -168], [-125, 8], [-48, 160]]
    readonly property var rOff: [[8, -158], [125, 40], [-6, 168]]

    Repeater {
        model: 3
        NetLink { required property int index; anchors.fill: v; flow: v.shown; tone: v.leftNode.tone ?? Theme.accent
                  x1: v.lx; y1: v.ly; x2: v.lx + v.lOff[index][0]; y2: v.ly + v.lOff[index][1] }
    }
    Repeater {
        model: 3
        NetLink { required property int index; anchors.fill: v; flow: v.shown; tone: v.rightNode.tone ?? Theme.accent2
                  x1: v.rx; y1: v.ry; x2: v.rx + v.rOff[index][0]; y2: v.ry + v.rOff[index][1] }
    }
    NetLink { anchors.fill: v; flow: v.shown; x1: v.lx; y1: v.ly; x2: v.rx; y2: v.ry }

    NetNode { x: v.lx - width / 2; y: v.ly - height / 2; shown: v.shown
              tone: v.leftNode.tone ?? Theme.accent; icon: v.leftNode.icon ?? "devices"; title: v.leftNode.title ?? ""; status: v.leftNode.status ?? ""; online: v.leftNode.online ?? true }
    NetNode { x: v.rx - width / 2; y: v.ry - height / 2; shown: v.shown
              tone: v.rightNode.tone ?? Theme.accent2; icon: v.rightNode.icon ?? "devices"; title: v.rightNode.title ?? ""; status: v.rightNode.status ?? ""; online: v.rightNode.online ?? false }

    Repeater {
        model: v.leftNode.chips ?? []
        NetChip { required property var modelData; required property int index
                  x: v.lx + v.lOff[index][0] - width / 2; y: v.ly + v.lOff[index][1] - height / 2
                  shown: v.shown; delay: 250 + index * 110
                  icon: modelData.icon; value: modelData.value; label: modelData.label }
    }
    Repeater {
        model: v.rightNode.chips ?? []
        NetChip { required property var modelData; required property int index
                  x: v.rx + v.rOff[index][0] - width / 2; y: v.ry + v.rOff[index][1] - height / 2
                  shown: v.shown; delay: 420 + index * 110
                  icon: modelData.icon; value: modelData.value; label: modelData.label }
    }
}
