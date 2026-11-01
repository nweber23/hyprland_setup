import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Password vault: a front end for a KeePassXC database (~/.local/share/passwords/vault.kdbx). All the cryptography is done
// by keepassxc-cli through bin/vault; the master password goes to that helper once, on its standard input, and is never kept here.
// Enter copies the password (cleared after 30 s), Shift+Enter types user, Tab, password into the window behind (wtype).
Panel {
    id: root
    name: "vault"
    backdrop: "Grid"
    panelWidth: 580
    centered: true
    fixedH: 560
    animateHeight: false

    readonly property string db: Quickshell.env("HOME") + "/.local/share/passwords/vault.kdbx"
    property bool dbExists: false
    property bool unlocked: false
    property bool busy: false
    property string error: ""
    property string note: ""
    property var entries: []
    property string query: ""
    property int sel: 0
    property bool adding: false
    property string deleteArmed: ""     // path of the entry whose delete was clicked once
    property int nextId: 1
    property var pending: ({})          // request id -> callback
    property var queued: null           // a request waiting for the helper to start
    readonly property var shownEntries: {
        const q = query.trim().toLowerCase()
        return q === "" ? entries : entries.filter(e => (e.title + " " + e.username + " " + e.url + " " + e.group).toLowerCase().includes(q))
    }
    readonly property var current: shownEntries.length > 0 ? shownEntries[Math.min(sel, shownEntries.length - 1)] : null

    // ---- the helper process: one JSON request per line in, one JSON answer per line out ----
    Process {
        id: helper
        command: ["vault", "serve", root.db]
        stdinEnabled: true
        stdout: SplitParser { onRead: line => root.onAnswer(line) }
        onStarted: if (root.queued) { helper.write(JSON.stringify(root.queued) + "\n"); root.queued = null }
        onRunningChanged: if (!running) { root.unlocked = false; root.entries = []; root.busy = false; root.adding = false }
    }
    function send(req, cb) {
        req.id = nextId++
        pending[req.id] = cb
        if (helper.running) helper.write(JSON.stringify(req) + "\n")
        else { queued = req; helper.running = true }
    }
    function onAnswer(line) {
        let r
        try { r = JSON.parse(line) } catch (e) { return }
        const cb = pending[r.id]
        if (cb) { delete pending[r.id]; cb(r) }
        else if (!r.ok && r.error) error = r.error
    }
    function checkDb() { dbCheck.running = true }
    Process { id: dbCheck; command: ["test", "-f", root.db]; onExited: code => root.dbExists = code === 0 }

    // ---- actions ----
    function unlock(pw) {
        if (pw === "" || busy) return
        busy = true; error = ""
        send({ cmd: "unlock", pw: pw }, r => {
            busy = false
            if (r.ok) { entries = r.entries; unlocked = true; sel = 0; query = ""; idle.restart(); searchInput.forceActiveFocus() }
            else { error = r.error; helper.running = false }
        })
    }
    function lock() {
        if (helper.running) { helper.write(JSON.stringify({ id: 0, cmd: "lock" }) + "\n"); helper.running = false }
        unlocked = false; entries = []; query = ""; adding = false; note = ""
    }
    function copy(field) {
        if (!current) return
        idle.restart()
        send({ cmd: "copy", path: current.path, field: field }, r => {
            note = r.ok ? (field === "password" ? "Password copied, cleared in 30 s" : field === "totp" ? "Code copied, cleared in 30 s" : "Copied") : r.error
        })
    }
    function typeLogin(mode) {
        if (!current) return
        const path = current.path
        Popups.close()   // the window behind gets the keys: give it back the focus first
        send({ cmd: "type", path: path, mode: mode, delay: 450 }, r => { if (!r.ok) error = r.error })
    }
    function openUrl() {
        if (current && /^https?:\/\//.test(current.url)) { Quickshell.execDetached(["xdg-open", current.url]); Popups.close() }
    }
    function remove() {
        if (!current) return
        if (deleteArmed !== current.path) { deleteArmed = current.path; disarm.restart(); return }
        deleteArmed = ""
        send({ cmd: "delete", path: current.path }, r => { if (r.ok) { entries = r.entries; note = "Moved to the recycle bin" } else error = r.error })
    }
    Timer { id: disarm; interval: 3000; onTriggered: root.deleteArmed = "" }
    // locks itself: after 5 minutes without use, a minute after the panel was closed, and with the screen lock
    Timer { id: idle; interval: 300000; onTriggered: root.lock() }
    Timer { id: closedLock; interval: 60000; onTriggered: root.lock() }
    Connections { target: Popups; function onLockedChanged() { if (Popups.locked) root.lock() } }
    onShownChanged: {
        if (shown) { closedLock.stop(); checkDb(); error = ""; note = ""; if (unlocked) searchInput.forceActiveFocus(); else pwInput.forceActiveFocus() }
        else if (unlocked) closedLock.restart()
    }

    // ---- creating a vault ----
    Process {
        id: creator
        command: ["vault", "create", root.db]
        stdinEnabled: true
        stdout: StdioCollector { onStreamFinished: {
            root.busy = false
            let r = {}
            try { r = JSON.parse(text) } catch (e) { r = { ok: false, error: "Could not create the vault" } }
            if (r.ok) { root.dbExists = true; root.error = ""; root.unlock(root.created); root.created = "" }
            else root.error = r.error
        } }
    }
    property string created: ""
    function createVault(a, b) {
        if (busy) return
        busy = true; error = ""; created = a
        creator.running = true
        creator.write(a + "\n" + b + "\n")
    }

    // ================= content =================
    Reveal {
        p: root; index: 0; dy: 8
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            Icon { name: root.unlocked ? "lock_open" : "lock"; size: 22; color: root.unlocked ? Theme.accent2 : Theme.accent }
            Text { Layout.fillWidth: true; textFormat: Text.PlainText; text: "Passwords"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 16; font.bold: true }
            SettingButton { visible: root.unlocked && !root.adding; label: "New"; accent: true; onClicked: { root.form = ({}); root.adding = true; root.note = ""; root.error = "" } }
            SettingButton { visible: root.unlocked; label: "Lock"; onClicked: root.lock() }
        }
    }

    // ---- no vault yet ----
    Reveal {
        p: root; index: 1; dy: 12
        visible: !root.dbExists
        Text { Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText
               text: "There is no vault yet. Choose a master password: it is the only thing that opens it, and it cannot be recovered. Use a long phrase and write it down somewhere safe."
               color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 11 }
        Rectangle { Layout.fillWidth: true; implicitHeight: 42; radius: 12; color: Theme.card
            TextInput { id: newPw1; anchors { fill: parent; leftMargin: 14; rightMargin: 14 } verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
                        color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 14; clip: true
                        KeyNavigation.tab: newPw2; Keys.onReturnPressed: newPw2.forceActiveFocus()
                        Text { visible: newPw1.text === ""; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText; text: "Master password (at least 8 characters)"; color: Theme.outline; font: newPw1.font } } }
        Rectangle { Layout.fillWidth: true; implicitHeight: 42; radius: 12; color: Theme.card
            TextInput { id: newPw2; anchors { fill: parent; leftMargin: 14; rightMargin: 14 } verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
                        color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 14; clip: true
                        Keys.onReturnPressed: { root.createVault(newPw1.text, newPw2.text); newPw1.text = ""; newPw2.text = "" }
                        Text { visible: newPw2.text === ""; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText; text: "Again"; color: Theme.outline; font: newPw2.font } } }
        SettingButton { label: root.busy ? "Creating…" : "Create vault"; accent: true
                        onClicked: { root.createVault(newPw1.text, newPw2.text); newPw1.text = ""; newPw2.text = "" } }
    }

    // ---- locked ----
    Reveal {
        p: root; index: 1; dy: 12
        visible: root.dbExists && !root.unlocked
        Text { Layout.topMargin: 30; Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: "Enter the master password"
               color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
        Rectangle {
            Layout.fillWidth: true; Layout.leftMargin: 40; Layout.rightMargin: 40; implicitHeight: 46; radius: 23; color: Theme.card
            border.width: 1; border.color: root.error !== "" ? Theme.error : Qt.alpha(Theme.outline_variant, 0.8)
            Behavior on border.color { ColorAnimation { duration: 160 } }
            TextInput { id: pwInput; anchors { fill: parent; leftMargin: 20; rightMargin: 20 } verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
                        passwordCharacter: "●"; color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 15; clip: true; enabled: !root.busy
                        Keys.onReturnPressed: { root.unlock(pwInput.text); pwInput.text = "" }
                        Keys.onEscapePressed: Popups.close()
                        Text { visible: pwInput.text === ""; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText
                               text: root.busy ? "Opening…" : "Password"; color: Theme.outline; font: pwInput.font } }
        }
    }

    // ---- unlocked: search and list ----
    Reveal {
        p: root; index: 1; dy: 12
        visible: root.unlocked && !root.adding
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 40; radius: 12; color: Theme.card
            RowLayout { anchors { fill: parent; leftMargin: 12; rightMargin: 12 } spacing: 8
                Icon { name: "search"; size: 18; color: Theme.on_surface_variant }
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true; clip: true
                    color: Theme.on_surface; selectionColor: Theme.primary; font.family: Theme.mono; font.pixelSize: 13
                    onTextChanged: { root.query = text; root.sel = 0; idle.restart() }
                    Keys.onDownPressed: root.sel = Math.min(root.shownEntries.length - 1, root.sel + 1)
                    Keys.onUpPressed: root.sel = Math.max(0, root.sel - 1)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { if (event.modifiers & Qt.ShiftModifier) root.typeLogin("login"); else root.copy("password") }
                        else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_U) root.copy("username")
                        else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_T) root.copy("totp")
                        else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_O) root.openUrl()
                        else if (event.key === Qt.Key_Delete && searchInput.text === "") root.remove()
                        else if (event.key === Qt.Key_Escape) Popups.close()
                        else return
                        event.accepted = true
                    }
                    Text { visible: searchInput.text === ""; textFormat: Text.PlainText; text: "Search " + root.entries.length + " entries…"; color: Theme.outline; font: searchInput.font }
                }
            }
        }
        ListView {
            id: list
            Layout.fillWidth: true; implicitHeight: 280
            clip: true; spacing: 4; model: root.shownEntries; currentIndex: root.sel
            boundsBehavior: Flickable.StopAtBounds
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: root.sel === index
                width: ListView.view.width; height: 52; radius: 12
                color: on ? Theme.primary_container : (hov.containsMouse ? Theme.surface_container_high : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }
                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 8 } spacing: 10
                    Rectangle { Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16; color: Theme.card
                                Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: row.modelData.title.charAt(0).toUpperCase(); color: Theme.accent; font.family: Theme.mono; font.pixelSize: 14; font.bold: true } }
                    ColumnLayout { Layout.fillWidth: true; spacing: 0
                        Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText; text: row.modelData.title
                               color: row.on ? Theme.on_primary_container : Theme.on_surface; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
                        Text { Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                               text: row.modelData.username + (row.modelData.group !== "" ? "   ·   " + row.modelData.group : "")
                               color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 10 } }
                    // actions for the highlighted row
                    Repeater {
                        model: row.on ? [{ i: "content_copy", t: "password" }, { i: "person", t: "username" }, { i: "keyboard", t: "type" }, { i: "pin", t: "totp" }, { i: "delete", t: "delete" }] : []
                        delegate: Rectangle {
                            required property var modelData
                            visible: modelData.t !== "totp" || row.modelData.totp
                            Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 15
                            color: ab.containsMouse ? Theme.primary : "transparent"
                            Icon { anchors.centerIn: parent; name: modelData.t === "delete" && root.deleteArmed === row.modelData.path ? "check" : modelData.i; size: 18
                                   color: modelData.t === "delete" && root.deleteArmed === row.modelData.path ? Theme.error : (ab.containsMouse ? Theme.on_primary : Theme.on_primary_container) }
                            MouseArea { id: ab; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { root.sel = row.index; modelData.t === "type" ? root.typeLogin("login") : modelData.t === "delete" ? root.remove() : root.copy(modelData.t) } }
                        }
                    }
                }
                MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; z: -1; onEntered: root.sel = row.index; onClicked: root.copy("password") }
            }
        }
        Text { visible: root.shownEntries.length === 0; Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText
               text: root.entries.length === 0 ? "The vault is empty. Add the first entry with New." : "Nothing matches"
               color: Theme.outline; font.family: Theme.mono; font.pixelSize: 12 }
    }

    // ---- unlocked: a new entry ----
    Reveal {
        p: root; index: 1; dy: 12
        visible: root.unlocked && root.adding
        // built fresh every time it opens, so the fields never keep what was typed for the previous entry
        Loader {
            Layout.fillWidth: true
            active: root.adding
            sourceComponent: Component {
                ColumnLayout {
                    spacing: 8
        Text { textFormat: Text.PlainText; text: "New entry"; color: Theme.on_surface_variant; font.family: Theme.mono; font.pixelSize: 12 }
        Repeater {
            model: [{ k: "title", h: "Title (e.g. GitHub)" }, { k: "username", h: "User name or e-mail" }, { k: "url", h: "Address (https://…)" }]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true; implicitHeight: 38; radius: 10; color: Theme.card
                TextInput { id: f; anchors { fill: parent; leftMargin: 12; rightMargin: 12 } verticalAlignment: TextInput.AlignVCenter; clip: true
                            color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12
                            onTextChanged: root.form[modelData.k] = text
                            Text { visible: f.text === ""; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText; text: modelData.h; color: Theme.outline; font: f.font } }
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Rectangle { Layout.fillWidth: true; implicitHeight: 38; radius: 10; color: Theme.card
                TextInput { id: newPass; anchors { fill: parent; leftMargin: 12; rightMargin: 12 } verticalAlignment: TextInput.AlignVCenter; clip: true
                            echoMode: showPass.checked ? TextInput.Normal : TextInput.Password
                            color: Theme.on_surface; font.family: Theme.mono; font.pixelSize: 12
                            onTextChanged: root.form.password = text
                            Text { visible: newPass.text === ""; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText; text: "Password (empty = make one)"; color: Theme.outline; font: newPass.font } } }
            SettingButton { label: "Generate"; onClicked: root.send({ cmd: "generate", length: 20 }, r => { if (r.ok) { newPass.text = r.password; showPass.checked = true } }) }
            Item { id: showPass; property bool checked: false; implicitWidth: 28; implicitHeight: 28
                   Icon { anchors.centerIn: parent; name: showPass.checked ? "visibility_off" : "visibility"; size: 18; color: Theme.on_surface_variant }
                   MouseArea { anchors.fill: parent; onClicked: showPass.checked = !showPass.checked } }
        }
        RowLayout {
            spacing: 8
            SettingButton { label: "Save"; accent: true
                            onClicked: {
                                if ((root.form.title ?? "").trim() === "") { root.error = "Give the entry a title"; return }
                                root.send({ cmd: "add", title: root.form.title.trim(), username: root.form.username ?? "", url: root.form.url ?? "", password: root.form.password ?? "" },
                                          r => { if (r.ok) { root.entries = r.entries; root.adding = false; root.form = ({}); root.note = "Saved" } else root.error = r.error })
                            } }
            SettingButton { label: "Cancel"; onClicked: { root.adding = false; root.form = ({}) } }
        }
                }
            }
        }
    }

    property var form: ({})

    // ---- status line ----
    Reveal {
        p: root; index: 2; dy: 6
        Text { Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText
               text: root.error !== "" ? root.error : root.note !== "" ? root.note
                     : root.unlocked ? "Enter copies the password · Shift+Enter types it · Ctrl+U user · Ctrl+T code · Ctrl+O open" : ""
               color: root.error !== "" ? Theme.error : root.note !== "" ? Theme.accent : Theme.outline; font.family: Theme.mono; font.pixelSize: 10 }
    }
}
