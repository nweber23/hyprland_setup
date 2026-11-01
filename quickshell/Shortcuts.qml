pragma Singleton
import Quickshell
import QtQuick

// Every key combination of this desktop, grouped, for the shortcut overview (Super+F1). Keep in step with hyprland.lua.
Singleton {
    readonly property var groups: [
        { title: "Apps", icon: "apps", items: [
            ["Super+R", "Launcher, calculator, emoji (:)"], ["Super+Q", "Terminal"], ["Super+B", "Browser"], ["Super+E", "Files"],
            ["Super+D", "Dock"], ["Super+W", "Wallpaper"], ["Super+Y", "Timer, notes, calculator"], ["Super+Shift+V", "Clipboard history"],
            ["Super+,", "Settings"], ["Super+Esc", "System monitor"], ["Super+T", "Screen time"] ] },
        { title: "Windows", icon: "web_asset", items: [
            ["Alt+Tab", "Window overview (hold, Tab moves)"], ["Super+Tab", "Same, with Super"], ["Super+Arrows", "Focus"], ["Super+Shift+Arrows", "Move window"],
            ["Super+Ctrl+Arrows", "Resize"], ["Super+C", "Close"], ["Super+F", "Fullscreen"], ["Super+Shift+F", "Maximize"],
            ["Super+V", "Float"], ["Super+J", "Toggle split"], ["Super+Drag", "Move"], ["Super+Right-drag", "Resize"] ] },
        { title: "Workspaces", icon: "grid_view", items: [
            ["Super+1..0", "Workspace on every screen"], ["Super+Shift+1..0", "Move window there"], ["Super+Ctrl+Tab", "Next workspace"],
            ["Super+Wheel", "Next / previous"], ["Super+O", "Workspace overview"], ["Super+S", "Scratchpad"], ["Super+Shift+S", "Send to scratchpad"],
            ["3 fingers", "Swipe sideways: workspace"] ] },
        { title: "Capture", icon: "photo_camera", items: [
            ["Print", "Screenshot, region"], ["Shift+Print", "Whole screen"], ["Super+Print", "Window"], ["Super+X", "Capture panel"],
            ["Super+Shift+R", "Record a region"], ["Super+Shift+T", "Copy text from the screen (OCR)"], ["Super+Shift+Q", "Read a QR code"],
            ["Super+Shift+C", "Pick a colour"] ] },
        { title: "System", icon: "settings_power", items: [
            ["Super+L", "Lock"], ["Super+M", "Log out"], ["Super+Space", "Next keyboard layout"], ["Alt+Shift", "Next keyboard layout"],
            ["Super+Shift+N", "Night light"], ["Super+Shift+G", "Game mode (no blur, no animations)"], ["Super+P", "Projection: duplicate, extend, one screen"],
            ["Super+`", "Drop-down terminal"], ["Super+F1", "This list"] ] },
        { title: "Keys on the keyboard", icon: "keyboard", items: [
            ["Volume keys", "Volume, mute"], ["Brightness keys", "Screen brightness"], ["Media keys", "Play, pause, next, previous"], ["Mic key", "Mute the microphone"] ] }
    ]
}
