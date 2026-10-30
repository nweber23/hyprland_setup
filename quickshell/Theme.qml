pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Material You palette. ~/.cache/quickshell/colors.json is written by matugen
// (see bin/set-wallpaper); this file watches it, so the whole UI recolours live.
Singleton {
    id: root

    property var raw: ({})
    function pick(name, fallback) { return raw[name] ?? fallback }

    property color primary:                pick("primary", "#d0bcff")
    property color on_primary:             pick("on_primary", "#381e72")
    property color primary_container:      pick("primary_container", "#4f378b")
    property color on_primary_container:   pick("on_primary_container", "#eaddff")
    property color secondary:              pick("secondary", "#ccc2dc")
    property color secondary_container:    pick("secondary_container", "#4a4458")
    property color on_secondary_container: pick("on_secondary_container", "#e8def8")
    property color tertiary:               pick("tertiary", "#efb8c8")
    property color error:                  pick("error", "#f2b8b5")
    property color surface:                pick("surface", "#141218")
    property color surface_container:      pick("surface_container", "#211f26")
    property color surface_container_high: pick("surface_container_high", "#2b2930")
    property color on_surface:             pick("on_surface", "#e6e0e9")
    property color on_surface_variant:     pick("on_surface_variant", "#cac4d0")
    property color outline:                pick("outline", "#938f99")
    property color outline_variant:        pick("outline_variant", "#49454f")

    // ---- Look of the panels (see the Serpantinum video): near-black tinted surfaces, one accent, one counter colour.
    readonly property color panelBg: Qt.darker(surface, 1.45)
    readonly property color card: Qt.tint(panelBg, Qt.alpha(on_surface, 0.055))     // inner boxes
    readonly property color cardHigh: Qt.tint(panelBg, Qt.alpha(on_surface, 0.10))  // chips, tracks
    readonly property color accent: primary
    readonly property color accent2: tertiary
    readonly property string mono: "JetBrains Mono"
    readonly property real radius: 14

    // Fade between palettes instead of snapping when the wallpaper changes.
    Behavior on primary                { ColorAnimation { duration: 600 } }
    Behavior on on_primary             { ColorAnimation { duration: 600 } }
    Behavior on primary_container      { ColorAnimation { duration: 600 } }
    Behavior on on_primary_container   { ColorAnimation { duration: 600 } }
    Behavior on secondary              { ColorAnimation { duration: 600 } }
    Behavior on secondary_container    { ColorAnimation { duration: 600 } }
    Behavior on on_secondary_container { ColorAnimation { duration: 600 } }
    Behavior on tertiary               { ColorAnimation { duration: 600 } }
    Behavior on surface                { ColorAnimation { duration: 600 } }
    Behavior on surface_container      { ColorAnimation { duration: 600 } }
    Behavior on surface_container_high { ColorAnimation { duration: 600 } }
    Behavior on on_surface             { ColorAnimation { duration: 600 } }
    Behavior on on_surface_variant     { ColorAnimation { duration: 600 } }
    Behavior on outline                { ColorAnimation { duration: 600 } }
    Behavior on outline_variant        { ColorAnimation { duration: 600 } }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.raw = JSON.parse(text()) } catch (e) { console.warn("Theme: bad colors.json:", e) }
        }
    }
}
