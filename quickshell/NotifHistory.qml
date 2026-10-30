pragma Singleton
import Quickshell
import QtQuick

// Missed and past notifications for the notification center (newest first, max 50, kept in memory).
Singleton {
    id: root
    property ListModel items: ListModel {}
    property int unread: 0

    function add(n) {
        items.insert(0, { app: n.appName, summary: n.summary, body: n.body,
                          icon: n.image !== "" ? n.image : (n.appIcon !== "" ? Quickshell.iconPath(n.appIcon, true) : ""),
                          time: Date.now() })
        while (items.count > 50) items.remove(items.count - 1)
        unread++
    }
    function remove(i) { items.remove(i) }
    function clear() { items.clear(); unread = 0 }
    function markRead() { unread = 0 }
}
