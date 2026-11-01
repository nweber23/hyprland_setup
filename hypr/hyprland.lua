-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/configuring/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
-- Laptop panel (1920x1080): scaled up for readability.
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1.25,
})

-- External Dell S3425DW, only connected sometimes. Matched by description so the
-- port (DP/HDMI/USB-C) does not matter. Placed to the right of the laptop panel.
hl.monitor({
    output   = "desc:Dell Inc. DELL S3425DW 6FWQQH4",
    mode     = "3440x1440@120",
    position = "auto-right",
    scale    = 1,
})

-- Fallback for any other display.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Per-machine overrides written by the shell's display panel (absent until used).
pcall(dofile, os.getenv("HOME") .. "/.config/hypr/monitors-local.lua")


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "quickshell ipc call shell toggle launcher"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
-- hl.on("hyprland.start", function () 
--   hl.exec_cmd(terminal)
--   hl.exec_cmd("nm-applet")
--   hl.exec_cmd("waybar & hyprpaper & firefox")
-- end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")   -- Electron apps (VS Code, Discord, ...) render natively instead of via blurry XWayland


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/configuring/core/config-options/
hl.config({
    general = {
        -- Clean look (as in Serpantinum): tight gaps and no window borders.
        gaps_in  = 4,
        gaps_out = 6,

        border_size = 0,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,
        extend_border_grab_area = 30,   -- grab the gap between windows to resize

        -- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 12,
        rounding_power = 3, -- 2 = plain circle; higher = smoother "squircle" corners

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = false,
            range        = 24,
            render_power = 3,
            color        = 0x66000000,
        },

        -- Blur is the main GPU cost on the Vega 6 iGPU: size 8 / 3 passes is the
        -- quality-per-cost sweet spot; lower passes first if frames drop.
        blur = {
            enabled           = true,
            size              = 8,
            passes            = 2,
            noise             = 0.02,
            vibrancy          = 0.17,
            new_optimizations = true,
            popups            = true,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Curves: Material-style "expressive" easing. The spatial ones overshoot slightly,
-- which is what makes windows feel springy; decel/accel pairs handle enter/exit.
hl.curve("expressiveFastSpatial",    { type = "bezier", points = { {0.42, 1.67}, {0.21, 0.90} } })
hl.curve("expressiveDefaultSpatial", { type = "bezier", points = { {0.38, 1.21}, {0.22, 1.00} } })
hl.curve("emphasizedDecel",          { type = "bezier", points = { {0.05, 0.70}, {0.10, 1.00} } })
hl.curve("emphasizedAccel",          { type = "bezier", points = { {0.30, 0.00}, {0.80, 0.15} } })
hl.curve("standardDecel",            { type = "bezier", points = { {0.00, 0.00}, {0.00, 1.00} } })
hl.curve("menuDecel",                { type = "bezier", points = { {0.10, 1.00}, {0.00, 1.00} } })
hl.curve("menuAccel",                { type = "bezier", points = { {0.52, 0.03}, {0.72, 0.08} } })
hl.curve("linear",                   { type = "bezier", points = { {0, 0}, {1, 1} } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 6,   bezier = "standardDecel" })
hl.animation({ leaf = "windows",       enabled = true, speed = 3.5, bezier = "expressiveDefaultSpatial" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 3.2, bezier = "expressiveFastSpatial", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 2.2, bezier = "emphasizedAccel",       style = "popin 88%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 3.5, bezier = "expressiveDefaultSpatial" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3,   bezier = "standardDecel" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 2.5, bezier = "standardDecel" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 2,   bezier = "menuAccel" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.5, bezier = "menuDecel" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3.5, bezier = "menuDecel",  style = "slide" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2,   bezier = "menuAccel",  style = "slide" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2.5, bezier = "standardDecel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2,   bezier = "menuAccel" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 4,   bezier = "emphasizedDecel", style = "slidefade 20%" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,   bezier = "standardDecel" })

-- Ref https://wiki.hypr.land/configuring/core/rules/workspace-rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- Do not stretch X11 windows (that is what makes them blurry at fractional scale). They scale
-- themselves from Xft.dpi instead, which bin/xdpi sets from the monitor scale.
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

-- See https://wiki.hypr.land/configuring/layouts/dwindle-layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/configuring/layouts/master-layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/configuring/layouts/scrolling-layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        focus_on_activate = false,       -- a window asking for attention does not steal focus
        disable_splash_rendering = true,
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
        allow_session_lock_restore = true, -- a new lock client may take over if the lock screen ever crashes (no lock-out)
    },
})


----------------
---- LAYERS ----
----------------

hl.config({
    layers = {
        allow_new_top_layers_over_existing_fullscreen = true, -- Set to false to make newly mapped top layers render below existing covering fullscreen window
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us,de",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",   -- Alt+Shift also switches the layout
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },

        -- The touchscreen (ELAN2514) belongs to the laptop panel, not the external monitor.
        touchdevice = {
            output = "eDP-1",
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- three fingers up: workspace overview, three fingers down: window overview (the same as Super+O and Alt+Tab held, tap to choose)
hl.gesture({ fingers = 3, direction = "up",
    action = { finish = function() hl.exec_cmd("quickshell ipc call shell toggle workspaces") end } })
hl.gesture({ fingers = 3, direction = "down",
    action = { finish = function() hl.exec_cmd("quickshell ipc call shell toggle switcher") end } })

-- Example per-device config
-- See https://wiki.hypr.land/configuring/core/devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/configuring/core/binds/ for more
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + M", hl.dsp.exit())  -- log out of Hyprland (back to the GDM login screen)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("quickshell ipc call shell toggle wallpaper"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("quickshell ipc call shell toggle screentime"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("quickshell ipc call shell toggle clipboard"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("quickshell ipc call shell lock"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))   -- next keyboard layout
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("record region"))   -- start/stop a region recording
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("screen-ocr"))    -- copy text from a region of the screen
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("screen-qr"))     -- read a QR code
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("colorpick"))     -- pick a colour
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("nightlight"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("quickshell ipc call shell toggle capture"))   -- screenshot / recording options
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("quickshell ipc call shell toggle tools"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("quickshell ipc call shell dock"))   -- show / hide the dock
hl.bind(mainMod .. " + SHIFT + G", function() qsGameMode(not qsGameModeOn) end)   -- game mode: no blur, no animations
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("quickshell ipc call shell toggle shortcuts"))   -- all shortcuts
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("quickshell ipc call shell toggle workspaces"))   -- workspace overview
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("quickshell ipc call shell toggle settings"))   -- settings
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("quickshell ipc call shell toggle sysmon"))   -- system monitor
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("google-chrome-stable --ozone-platform-hint=auto"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Every monitor has its own workspaces: the laptop panel owns 1-10, the next monitor 11-20, the one after 21-30 ...
-- (the others in name order). mainMod + N shows workspace N on ALL monitors at once, each on its own set.
local function wsOffset(name)
    if name:sub(1, 3) == "eDP" then return 0 end
    local names = {}
    for _, m in ipairs(hl.get_monitors()) do
        if m.name:sub(1, 3) ~= "eDP" then names[#names + 1] = m.name end
    end
    table.sort(names)
    for i, n in ipairs(names) do
        if n == name then return 10 * i end
    end
    return 0
end

-- Show workspace `id` on a monitor. One that still lives on another monitor (e.g. from before this scheme) is moved over first;
-- plain focusing would just jump to that other monitor instead.
local function showOn(monitorName, id)
    local ws = hl.get_workspace(id)
    if ws and ws.monitor and ws.monitor.name ~= monitorName then
        hl.dispatch(hl.dsp.workspace.move({ workspace = id, monitor = monitorName }))
    end
    hl.dispatch(hl.dsp.focus({ monitor = monitorName }))
    hl.dispatch(hl.dsp.focus({ workspace = id }))
end

-- Global on purpose: the bar calls it through `hyprctl eval` when a workspace dot is clicked.
function qsGotoWorkspace(n)
    local cur = hl.get_active_monitor().name
    local pos = hl.get_cursor_pos()   -- focusing a monitor warps the pointer to its centre: put it back afterwards
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= cur then showOn(m.name, n + wsOffset(m.name)) end
    end
    showOn(cur, n + wsOffset(cur))
    hl.dispatch(hl.dsp.cursor.move({ x = pos.x, y = pos.y }))
end

-- Focus a window and show its workspace number on every monitor (Alt+Tab, the overview). Global: the shell calls it
-- through `hyprctl eval`.
function qsFocusWindow(address)
    local target
    for _, w in ipairs(hl.get_windows()) do
        if w.address == address then target = w end
    end
    if not target then return end
    local id = target.workspace and target.workspace.id or 0
    if id > 0 then   -- special workspaces (scratchpad) have no number to share
        local n = (id - 1) % 10 + 1
        local pos = hl.get_cursor_pos()
        for _, m in ipairs(hl.get_monitors()) do showOn(m.name, n + wsOffset(m.name)) end
        hl.dispatch(hl.dsp.cursor.move({ x = pos.x, y = pos.y }))
    end
    hl.dispatch(hl.dsp.focus({ window = "address:" .. address }))
end

-- Game mode: no blur and no animations, for games and video on the small iGPU. The shell reads the state from
-- ~/.cache/quickshell/gamemode.txt (it also pauses an animated wallpaper). Global: the bar button and the key bind call it.
qsGameModeOn = false
function qsGameMode(on)
    qsGameModeOn = on and true or false
    hl.config({
        animations = { enabled = not qsGameModeOn },
        decoration = { blur = { enabled = not qsGameModeOn } },
    })
    local f = io.open(os.getenv("HOME") .. "/.cache/quickshell/gamemode.txt", "w")
    if f then f:write(qsGameModeOn and "1" or "0"); f:close() end
end
qsGameMode(false)   -- a fresh session always starts normal

-- Move a window to workspace number n of the monitor it is on (the workspace overview calls this when you drop a window on a card).
function qsMoveWindow(address, n)
    for _, w in ipairs(hl.get_windows()) do
        if w.address == address then
            local mon = w.monitor and w.monitor.name or hl.get_active_monitor().name
            hl.dispatch(hl.dsp.window.move({ workspace = n + wsOffset(mon), window = "address:" .. address }))
        end
    end
end

-- Step to the next / previous workspace number that has windows (or is showing now), on every monitor at once.
-- Global like qsGotoWorkspace so the binds below and the shell can use it.
function qsCycleWorkspace(dir)
    local cur = hl.get_active_monitor()
    local curId = cur.active_workspace and cur.active_workspace.id or 1
    local here = (curId - 1) % 10 + 1
    local open, nums = { [here] = true }, {}
    for _, ws in ipairs(hl.get_workspaces()) do
        if ws.id > 0 and (ws.windows > 0 or ws.active) then open[(ws.id - 1) % 10 + 1] = true end
    end
    for n in pairs(open) do nums[#nums + 1] = n end
    table.sort(nums)
    local at = 1
    for i, n in ipairs(nums) do
        if n == here then at = i end
    end
    qsGotoWorkspace(nums[(at - 1 + dir) % #nums + 1])
end

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace of the monitor it is on with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             function() qsGotoWorkspace(i) end)
    hl.bind(mainMod .. " + SHIFT + " .. key,     function() hl.dispatch(hl.dsp.window.move({ workspace = i + wsOffset(hl.get_active_monitor().name) })) end)
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + CTRL + Tab",         function() qsCycleWorkspace(1) end)
hl.bind(mainMod .. " + CTRL + SHIFT + Tab", function() qsCycleWorkspace(-1) end)
-- Window overview: Alt+Tab / Super+Tab.
--   * A quick tap (modifier up within ~150 ms) swaps windows right here, with no overview and no round trip to the shell.
--   * Holding the modifier opens the overview; Tab moves on, releasing the modifier switches.
-- Hyprland watches the modifier itself: the overview only gets keyboard focus after the modifier is already down,
-- so neither it nor a release bind sees the key coming up.
local overview = { timer = nil, ticks = 0, steps = 0, opened = false }

local function mruWindows()   -- mapped windows, focused one first
    local list = {}
    for _, w in ipairs(hl.get_windows()) do
        if w.mapped and not w.hidden then list[#list + 1] = w end
    end
    table.sort(list, function(a, b) return a.focus_history_id < b.focus_history_id end)
    return list
end

local function swapDirect(steps)
    local list = mruWindows()
    local n = #list
    if n < 2 then return end
    local w = list[(steps % n) + 1]   -- list[1] is the focused window; steps = number of Tab presses (negative with Shift)
    qsFocusWindow(w.address)
end

local function overviewKey(dir, modKeys)
    local o = overview
    if o.timer then   -- the modifier is still down: another step
        o.steps = o.steps + dir
        if o.opened then hl.exec_cmd("quickshell ipc call shell switcher " .. dir) end
        return
    end
    o.steps, o.ticks, o.opened = dir, 0, false
    o.timer = hl.timer(function()
        o.ticks = o.ticks + 1
        local down = false
        for _, k in ipairs(modKeys) do if hl.is_key_down(k) then down = true end end
        if not down then   -- released
            o.timer:set_enabled(false); o.timer = nil
            if o.opened then hl.exec_cmd("quickshell ipc call shell switcherConfirm") else swapDirect(o.steps) end
        elseif not o.opened and o.ticks >= 5 then   -- still held after ~150 ms: show the overview
            o.opened = true
            hl.exec_cmd("quickshell ipc call shell switcherOpen " .. o.steps)
        end
    end, { timeout = 30, type = "repeat" })
end

hl.bind("ALT + Tab",         function() overviewKey(1,  { "Alt_L", "Alt_R" }) end)
hl.bind("ALT + SHIFT + Tab", function() overviewKey(-1, { "Alt_L", "Alt_R" }) end)
hl.bind(mainMod .. " + Tab",         function() overviewKey(1,  { "Super_L", "Super_R" }) end)
hl.bind(mainMod .. " + SHIFT + Tab", function() overviewKey(-1, { "Super_L", "Super_R" }) end)
hl.bind(mainMod .. " + mouse_down", function() qsCycleWorkspace(1) end)
hl.bind(mainMod .. " + mouse_up",   function() qsCycleWorkspace(-1) end)

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("volume up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("volume down"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("volume mute"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/configuring/core/rules/

-- Example window rules that are useful

-- Small utility windows and file dialogs float, centred, instead of tiling.
hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(nm-connection-editor|pavucontrol|org.gnome.Calculator|gnome-calculator|blueman-manager|nm-openvpn-auth-dialog|org.gnome.NautilusPreviewer|xdg-desktop-portal-gtk)$" },
    float = true,
    center = true,
})
hl.window_rule({
    name  = "float-file-dialogs",
    match = { title = "^(Open File|Open Files|Open Folder|Save As|Save File|Save Image|File Upload|Select .*|Choose .*)$" },
    float = true,
    center = true,
})
hl.window_rule({
    name  = "picture-in-picture",
    match = { title = "^(Picture-in-Picture|Picture in picture)$" },
    float = true,
    pin   = true,
})

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})



-----------------------------
---- EXTRA KEYBINDINGS    ----
-----------------------------

-- Move windows with SUPER+SHIFT+arrows
for _, d in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + SHIFT + " .. d, hl.dsp.window.move({ direction = d }))
end

-- Resize the active window with SUPER+CTRL+arrows (hold to repeat)
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })

-- Fullscreen / maximize
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Screenshots: region to clipboard, or region saved to ~/Pictures
hl.bind("Print",                 hl.dsp.exec_cmd("screenshot region"))
hl.bind("SHIFT + Print",         hl.dsp.exec_cmd("screenshot full"))
hl.bind(mainMod .. " + Print",   hl.dsp.exec_cmd("screenshot window"))


------------------------------
---- QUICKSHELL (bar, UI) ----
------------------------------

-- Keyboard layouts chosen in the shell's settings (absent until used). Loaded last so it wins over the input block above.
pcall(dofile, os.getenv("HOME") .. "/.config/hypr/input-local.lua")

-- Wallpaper colours for the window borders (generated by matugen; absent until set-wallpaper ran once).
pcall(dofile, os.getenv("HOME") .. "/.cache/hypr-colors.lua")

-- Quickshell draws the wallpaper, the bar and all panels; config lives in ~/dotfiles/quickshell.
hl.on("hyprland.start", function()
    -- portals and systemd user services need to know the Wayland display
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("xdpi")
    hl.exec_cmd("nm-applet --indicator")   -- tray icon with the full network menu (hidden networks, VPN, edit connections)
    hl.exec_cmd("env QS_ICON_THEME=Papirus quickshell")   -- Papirus covers Steam games, calculator, drivers...; candy-icons (the GNOME theme) lacks them
end)

-- Blur what is behind the bar pills; ignore_alpha keeps fully transparent gaps unblurred.
hl.layer_rule({
    name        = "qs-bar-blur",
    match       = { namespace = "qs-bar" },
    blur        = true,
    ignore_alpha = 0.3,
})

-- Popup panels: blurred, and no compositor animation (Quickshell animates them itself).
hl.layer_rule({
    name         = "qs-panel",
    match        = { namespace = "qs-panel" },
    blur         = true,
    ignore_alpha = 0.3,
    no_anim      = true,
})

-- Window overview (Alt+Tab): blur the screen behind its dimming layer; Quickshell animates it itself.
hl.layer_rule({
    name         = "qs-overview",
    match        = { namespace = "qs-overview" },
    blur         = true,
    ignore_alpha = 0.1,
    no_anim      = true,
})

-- App dock: blurred like the bar; Quickshell animates it itself.
hl.layer_rule({
    name         = "qs-dock",
    match        = { namespace = "qs-dock" },
    blur         = true,
    ignore_alpha = 0.3,
    no_anim      = true,
})
