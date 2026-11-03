.pragma library

// Launch targets (2026-10-11): one string names something to open, so a Qwidget, a future dashboard tab
// or the CLI can store "what to open" without knowing how (core/Launch.qml runs it; IPC `launch run
// <target>`; the future vtnc CLI: `vtnc open <target>`).
//  - vtnc:<appId>          a shell app (apps/AppRegistry.qml)
//  - vtnc:settings/<page>  the settings on a page (as the `settings page` IPC)
//  - desktop:<entry id>    a desktop application (its .desktop id, e.g. "firefox")
// (a raw `cmd:` is left for the CLI.)

var VTNC_APPS = {
    launcher: { title: "Launcher", icon: "magnifyingGlass" },
    settings: { title: "Settings", icon: "gear" },
    wallpaper: { title: "Wallpapers", icon: "image" },
    tools: { title: "Tools", icon: "camera" },
    session: { title: "Session", icon: "power" },
    dashboard: { title: "Dashboard", icon: "squaresFour" }
};

// "vtnc:settings/appearance" → { kind: "vtnc", id: "settings", arg: "appearance" }; null when invalid
function parse(target) {
    var m = /^(vtnc|desktop):(.+)$/.exec(typeof target === "string" ? target.trim() : "");
    if (!m)
        return null;
    if (m[1] === "desktop")
        return { kind: "desktop", id: m[2], arg: "" };
    var slash = m[2].indexOf("/");
    var id = slash < 0 ? m[2] : m[2].slice(0, slash);
    var arg = slash < 0 ? "" : m[2].slice(slash + 1);
    if (!VTNC_APPS.hasOwnProperty(id) || (arg !== "" && id !== "settings"))
        return null;
    return { kind: "vtnc", id: id, arg: arg };
}

function valid(target) {
    return parse(target) !== null;
}

function format(kind, id, arg) {
    return kind + ":" + id + (arg ? "/" + arg : "");
}
