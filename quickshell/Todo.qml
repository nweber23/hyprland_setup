pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// To-do list for the desktop widget, kept in ~/.config/quickshell-local/todo.json: [{ text, done }]
Singleton {
    id: root
    property var items: []
    readonly property int left: items.filter(i => !i.done).length

    function save(list) { items = list; file.setText(JSON.stringify(list)) }
    function add(t) { t = t.trim(); if (t !== "") save(items.concat([{ text: t, done: false }])) }
    function toggle(i) { save(items.map((it, n) => n === i ? { text: it.text, done: !it.done } : it)) }
    function remove(i) { save(items.filter((_, n) => n !== i)) }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell-local/todo.json"
        printErrors: false
        onLoaded: {
            try { root.items = JSON.parse(text()).filter(i => i && typeof i.text === "string").map(i => ({ text: i.text, done: i.done === true })) }
            catch (e) { console.warn("Todo: bad todo.json:", e) }
        }
    }
}
