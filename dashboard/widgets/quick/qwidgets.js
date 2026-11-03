.pragma library

// Qwidget catalog: the mini widgets of the Quick configs Dwidget and Iwidget (see ../README.md, "Quick
// configs"). Since 2026-10-11 they're not only toggles: Quick configs is a wildcard, a dashboard inside
// the dashboard (the user builds their own Session / Tools / apps Dwidget out of it), so:
//  - kind: toggle (on / off) · action (runs something: a tool, a session action, the next scheme) ·
//    app (opens a launch target, core/launch.js)
//  - group: where the settings offer it (GROUPS)
//  - title / icon: for the settings chips (icon = a property name of theme/Icons.qml); the live icon
//    and state come from the model (Models.qml)
//  - panel: it has a panel (right-click, expanding the Dwidget); island: false = not on the island
//    (the Mixer only opens its panel)
//  - tool / action: the Tools / Session action it runs (apps/tools/actions.js, apps/session/actions.js)
//  - config: "target" = each instance picks what it opens (the App Qwidget)
// options.items is the ordered list shown: an id ("caffeine") or a configured instance ({ id: "app",
// target: "desktop:firefox" }). Any Qwidget may repeat (five Caffeines is fine), up to MAX_ITEMS. The
// rect's size decides how they're arranged (arrange()).

var MAX_ITEMS = 24;

var GROUPS = [
    { id: "connections", title: "Connections" },
    { id: "appearance", title: "Appearance" },
    { id: "system", title: "System" },
    { id: "sound", title: "Sound" },
    { id: "apps", title: "Apps" },
    { id: "tools", title: "Tools" },
    { id: "session", title: "Session" }
];

// in GROUPS order (available() lists them in this order)
var QWIDGETS = {
    wifi: { title: "Wi-Fi", icon: "wifiHigh", panel: true, kind: "toggle", group: "connections" },
    bluetooth: { title: "Bluetooth", icon: "bluetooth", panel: true, kind: "toggle", group: "connections" },
    nightLight: { title: "Temperature", icon: "thermometer", panel: true, kind: "toggle", group: "appearance" },
    lightMode: { title: "Light mode", icon: "sun", panel: false, kind: "toggle", group: "appearance" },
    scheme: { title: "Color scheme", icon: "palette", panel: true, kind: "action", group: "appearance" },
    // a click opens the Wallpaper app; its panel (2026-10-27) picks one, or a random one
    wallpaper: { title: "Wallpaper", icon: "image", panel: true, kind: "action", group: "appearance" },
    transparency: { title: "Transparency", icon: "transparency", panel: false, kind: "toggle", group: "appearance" },
    caffeine: { title: "Caffeine", icon: "caffeine", panel: false, kind: "toggle", group: "system" },
    dnd: { title: "Do not disturb", icon: "bellSlash", panel: false, kind: "toggle", group: "system" },
    gameMode: { title: "Game mode", icon: "gameMode", panel: false, kind: "toggle", group: "system" },
    powerProfile: { title: "Power profile", icon: "gauge", panel: true, kind: "toggle", group: "system" },
    microphone: { title: "Microphone", icon: "mic", panel: false, kind: "toggle", group: "sound" },
    mixer: { title: "Mixer", icon: "faders", panel: true, kind: "toggle", group: "sound", island: false },
    app: { title: "App", icon: "apps", panel: false, kind: "app", group: "apps", config: "target" },
    settings: { title: "Settings", icon: "gear", panel: false, kind: "app", group: "apps" },
    shotRegion: { title: "Screenshot region", icon: "selection", panel: false, kind: "action", group: "tools", tool: "shot-region" },
    shotScreen: { title: "Screenshot screen", icon: "monitor", panel: false, kind: "action", group: "tools", tool: "shot-screen" },
    recRegion: { title: "Record region", icon: "screencast", panel: false, kind: "action", group: "tools", tool: "rec-region" },
    recScreen: { title: "Record screen", icon: "monitorPlay", panel: false, kind: "action", group: "tools", tool: "rec-screen" },
    recAudio: { title: "Record + audio", icon: "microphone", panel: false, kind: "action", group: "tools", tool: "rec-audio" },
    colorPicker: { title: "Color picker", icon: "eyedropper", panel: false, kind: "action", group: "tools", tool: "picker" },
    ocr: { title: "OCR", icon: "textT", panel: false, kind: "action", group: "tools", tool: "ocr" },
    lock: { title: "Lock", icon: "lock", panel: false, kind: "action", group: "session", action: "lock" },
    suspend: { title: "Suspend", icon: "suspend", panel: false, kind: "action", group: "session", action: "suspend" },
    hibernate: { title: "Hibernate", icon: "hibernate", panel: false, kind: "action", group: "session", action: "hibernate" },
    logout: { title: "Log out", icon: "logout", panel: false, kind: "action", group: "session", action: "logout" },
    reboot: { title: "Reboot", icon: "reboot", panel: false, kind: "action", group: "session", action: "reboot" },
    poweroff: { title: "Power off", icon: "shutdown", panel: false, kind: "action", group: "session", action: "poweroff" }
};

var DEFAULT_ITEMS = ["wifi", "bluetooth", "nightLight", "caffeine", "gameMode", "dnd"];

function has(id) {
    return QWIDGETS.hasOwnProperty(id);
}

// `v` as a plain array when it is a list: a JS array, or the array-like sequence Qt makes of a list
// that went through a model (Array.isArray is false for those); else null
function asArray(v) {
    if (Array.isArray(v))
        return v;
    if (v && typeof v === "object" && typeof v.length === "number")
        return Array.prototype.slice.call(v);
    return null;
}

// the Qwidget id of a stored entry (an id, or an instance object) or of an instance key ("app#2")
function idOf(e) {
    if (typeof e === "string")
        return e.split("#")[0];
    return e && typeof e === "object" && typeof e.id === "string" ? e.id : "";
}

// whether the island shows it (`island` true: only those)
function allowed(id, island) {
    return has(id) && !(island && QWIDGETS[id].island === false);
}

// options.items as stored, valid entries only, in order, at most MAX_ITEMS (the defaults when missing):
// ids and instance objects ({ id, …config }); the settings editor writes this back
function raw(options, island) {
    var list = (options && asArray(options.items)) || DEFAULT_ITEMS;
    return list.filter(function (e) {
        return allowed(idOf(e), island);
    }).slice(0, MAX_ITEMS);
}

// the instances shown: { key, id, config } in order. `key` is unique ("caffeine#1", "caffeine#2", by
// order among the same id); `config` the entry's options ({} for a plain id)
function items(options, island) {
    var count = {};
    return raw(options, island).map(function (e) {
        var id = idOf(e);
        count[id] = (count[id] || 0) + 1;
        var config = {};
        if (typeof e === "object")
            for (var k in e)
                if (k !== "id")
                    config[k] = e[k];
        return { key: id + "#" + count[id], id: id, config: config };
    });
}

// what can still be added: every Qwidget (they repeat), in catalog order; none at MAX_ITEMS. `shown`
// is the shown list (only its length counts)
function available(shown, island) {
    if (shown && shown.length >= MAX_ITEMS)
        return [];
    return Object.keys(QWIDGETS).filter(function (id) {
        return allowed(id, island);
    });
}

// how `n` Qwidgets fit a w × h rect with gap `g`: { kind: "pills" | "icons", per } (pills per row).
// Pills (icon, name, state) need rows of `minRow` px (44 by default) and `minCol` px wide (120): as few
// per row as fit the height;
// else a short or narrow rect gets icons
function arrange(n, w, h, g, minRow, minCol) {
    var row = minRow || 44;
    var col = minCol || 120;
    for (var per = 1; per <= Math.max(1, n); per++) {
        var rows = Math.ceil(n / per);
        if ((w - g * (per - 1)) / per < col)
            break;
        if ((h - g * (rows - 1)) / rows >= row)
            return { kind: "pills", per: per };
    }
    return { kind: "icons", per: 0 };
}

// `ids` split into `rows` rows as even as possible (the first ones one longer)
function split(ids, rows) {
    var per = Math.ceil(ids.length / Math.max(1, rows));
    var out = [];
    for (var i = 0; i < ids.length; i += per)
        out.push(ids.slice(i, i + per));
    return out;
}

// the rows and side that make `n` squares the biggest in w × h with gap g: { rows, side }
function squares(n, w, h, g) {
    var best = { rows: 1, side: 0 };
    for (var r = 1; r <= Math.max(1, n); r++) {
        var c = Math.ceil(n / r);
        var side = Math.min((w - g * (c - 1)) / c, (h - g * (r - 1)) / r);
        if (side > best.side + 0.5)
            best = { rows: r, side: side };
    }
    return best;
}

