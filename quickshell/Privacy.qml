pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Who is using the microphone, the camera or sharing the screen right now, read from PipeWire's streams.
Singleton {
    id: root
    property var mic: []        // app names
    property var camera: []
    property var screen: []

    PwObjectTracker { objects: Pipewire.nodes.values }   // makes the node properties available

    function appName(p) { return p["application.name"] || p["node.name"] || "app" }
    function scan() {
        const mic = [], cam = [], scr = []
        for (const n of Pipewire.nodes.values) {
            const p = n.properties
            if (!p) continue
            const cls = p["media.class"] ?? ""
            const name = root.appName(p)
            if (name === "Quickshell" || String(p["node.name"] ?? "").startsWith("qs_eq") || String(p["node.name"] ?? "").startsWith("qs_spectrum")) continue   // our own equalizer and music bars
            if (cls === "Stream/Input/Audio") mic.push(name)
            else if (cls === "Stream/Input/Video") (p["media.role"] === "Camera" ? cam : scr).push(name)
            else if (cls === "Stream/Output/Video") scr.push(name)   // the portal's screencast source
        }
        const uniq = a => a.filter((x, i) => a.indexOf(x) === i)
        root.mic = uniq(mic); root.camera = uniq(cam); root.screen = uniq(scr)
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.scan() }
}
