import QtQuick

// Sliding highlight that stretches: the edge in the direction of travel moves first, the other follows.
//   ElasticPill { target: <start of the slot>; extent: <slot length>; vertical: false; cross: 4; crossSize: 26 }
Rectangle {
    id: root
    property real target: 0
    property real extent: 40
    property bool vertical: false
    property real cross: 0        // position on the other axis
    property real crossSize: 30   // size on the other axis
    property real a: target                 // start edge
    property real b: target + extent        // end edge
    Behavior on a { NumberAnimation { duration: root.target > root.a ? 300 : 140; easing.type: Easing.OutCubic } }
    Behavior on b { NumberAnimation { duration: root.target + root.extent > root.b ? 140 : 300; easing.type: Easing.OutCubic } }
    x: vertical ? cross : a;  width: vertical ? crossSize : b - a
    y: vertical ? a : cross;  height: vertical ? b - a : crossSize
    color: Theme.accent
}
