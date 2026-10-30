import QtQuick

// Big, barely visible circles behind panel content. Parent is expected to clip.
Item {
    id: root
    property color tint: Theme.accent
    anchors.fill: parent
    Rectangle { x: root.width * 0.30; y: -root.height * 0.15; width: root.height * 1.15; height: width; radius: width / 2; color: Qt.alpha(root.tint, 0.045) }
    Rectangle { x: root.width * 0.55; y: root.height * 0.20; width: root.height * 0.95; height: width; radius: width / 2; color: Qt.alpha(root.tint, 0.04) }
    Rectangle { x: -root.width * 0.10; y: root.height * 0.45; width: root.height * 0.8; height: width; radius: width / 2; color: Qt.alpha(root.tint, 0.03) }
}
