.pragma library
.import "../../island/widgets/catalog.js" as Catalog
.import "../../dashboard/widgets/catalog.js" as DCatalog
.import "../theme/colorRoles.js" as ColorRoles

// Validates one config / state file (core/STATE.md) against its factory defaults.
// - missing keys are filled from defaults
// - values with the wrong type fall back to the default
// - enum-like fields are checked against ENUMS
// - unknown keys are kept (JsonAdapter ignores what it doesn't declare)

var TEXT_COLORS = ["default", "primary", "secondary", "tertiary", "variant"];
var TEXT_BACKGROUNDS = ["none", "container", "tonal", "primary"];

var ENUMS = {
    "island.style": ["notch", "island"],
    // auto-hide level: 1 fullscreen · 2 fullscreen or windows on the workspace · 3 always
    "island.autohide_nv": [1, 2, 3],
    // new notification per island mode: the island becomes the card, or only the bell reacts
    "island.notifications.compact": ["transient", "widget"],
    "island.notifications.expanded": ["transient", "widget"],
    // the notification card's look and tone (island/transient/NotificationCard.qml)
    "island.notifications.style": ["shapes", "tones", "tone"],
    "island.notifications.color": ["primary", "surface", "variant", "secondary", "tertiary"],
    // the clock / date iwidgets' colour role and background (iwidgets/clock/TextPill.qml)
    "island.clock.color": TEXT_COLORS,
    "island.clock.background": TEXT_BACKGROUNDS,
    "island.date.color": TEXT_COLORS,
    "island.date.background": TEXT_BACKGROUNDS,
    // the visualizer Iwidget's colour
    "island.visualizer.color": ["primary", "surface", "variant", "secondary", "tertiary"],
    "island.visualizer.source": ["music", "random"],
    // the Quick configs Iwidget's Two tones colour
    "island.quick.color": ["primary", "surface", "variant", "secondary", "tertiary"],
    // the active window Iwidget's text per island mode (iwidgets/window)
    "island.window.compact.text": ["both", "first", "second", "none"],
    "island.window.expanded.text": ["both", "first", "second", "none"],
    // the battery Iwidget's tone and what it shows per island mode
    "island.battery.color": ["primary", "surface", "variant", "secondary", "tertiary"],
    "island.battery.compact.show": ["both", "icon", "text"],
    "island.battery.expanded.show": ["both", "icon", "text"],
    // the tray Iwidget's compact per island mode: off, or where the icons open (< left, > right)
    "island.tray.compact.fold": ["off", "left", "right"],
    "island.tray.expanded.fold": ["off", "left", "right"],
    // the tray Iwidget's tint colour
    "island.tray.tintColor": ["primary", "surface", "variant", "secondary", "tertiary"],
    // what the active window shows with no window focused (2026-10-15)
    "island.window.idle.show": ["text", "media"],
    "island.workspaces.label": ["dot", "number", "roman", "japanese"],
    "island.workspaces.focus": ["pill", "shape"],
    "island.workspaces.windows.compact": ["icons", "apps", "off"],
    "island.workspaces.windows.expanded": ["icons", "apps", "off"],
    "island.dock.compact.content": ["dock", "open"],
    "island.dock.expanded.content": ["dock", "open"],
    "island.dock.compact.scope": ["workspace", "all"],
    "island.dock.expanded.scope": ["workspace", "all"],
    // when the media Iwidget goes away (2026-10-15)
    "island.media.visibility": ["never", "noMedia", "paused"],
    // the notification popup: replace the island or grow under it; expanded on hover or always (2026-10-15)
    "island.notifications.presentation": ["replace", "grow"],
    "island.notifications.expand": ["hover", "always"],
    "island.notifications.animation": ["slide", "fade"],
    // how an expanding Dwidget makes room (dwidgets/layout.js)
    "dashboard.expandMode": DCatalog.MODES,
    // the cards' colour, island and dashboard (kit/CardPalette.qml; one setting since 2026-10-11)
    "theme.card": DCatalog.CARDS,
    "theme.appStyle": ["shapes", "tones", "tone"],
    // the island apps' options (Settings → Apps, 2026-10-17)
    "apps.notifications.maxAgeDays": [0, 1, 7, 30],
    "apps.clipboard.previewLines": [1, 2],
    "apps.notes.format": ["markdown", "plain"],
    "apps.notes.font": ["ui", "mono"],
    "apps.dino.speed": ["normal", "fast"],
    "wallpapers.transition": ["none", "simple", "fade", "left", "right", "top", "bottom", "wipe", "wave", "grow", "center", "any", "outer", "random"],
    "theme.scheme": ["scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-tonal-spot", "scheme-vibrant"]
};

// section "off" = not in the island; per mode (compact / expanded) a style from the iwidget
// catalog or "hidden"
// Iwidget styles renamed (old → new: { <iwidget id>: { <old style>: "<new style>" } }), kept instead of
// falling back to the default. Empty since R2 C3 (2026-10-29: the old migrations went with the last old
// preset); a style renamed from now on goes here, with a test in core/tests/migrate.test.js
var RENAMED_STYLES = {};

var WIDGET_SECTIONS = ["off", "left", "center", "right"];
var WIDGET_MODES = ["compact", "expanded"];

function typeOf(v) {
    if (v === null)
        return "null";
    if (Array.isArray(v))
        return "array";
    return typeof v;
}

function clone(v) {
    return JSON.parse(JSON.stringify(v));
}

// Widgets are entries with a `uid`, and a `cardColor` when their card has its own colour (2026-10-11: an Iwidget may be on the island more than once, as the
// Dwidgets; old entries get uid = id). The original is uid = id, its copies `<id>-2`…: only the
// original may be in Off (an off copy is dropped, or becomes the original when there's none). Unknown
// ids and duplicate uids are dropped. An Iwidget without its original gets one: its factory entry
// when it has no entry at all (a new widget), else an off one (Off always offers each Iwidget). Styles are checked against
// the iwidget catalog.
function mergeWidgets(user, defaults) {
    if (typeOf(user) !== "array")
        return clone(defaults);

    var known = {};
    defaults.forEach(function (d) {
        known[d.id] = d;
    });

    var seenUid = {};
    var seenId = {};
    var out = [];
    var valid = function (w) {
        return typeOf(w) === "object" && known[w.id] && Catalog.has(w.id);
    };
    var uidOf = function (w) {
        return typeOf(w.uid) === "string" && w.uid !== "" ? w.uid : w.id;
    };
    // the Iwidgets whose original is in the list
    var originals = {};
    user.forEach(function (w) {
        if (valid(w) && uidOf(w) === w.id)
            originals[w.id] = true;
    });
    user.forEach(function (w) {
        if (!valid(w))
            return;
        var uid = uidOf(w);
        var d = known[w.id];
        var section = WIDGET_SECTIONS.indexOf(w.section) >= 0 ? w.section : d.section;
        // only the original may be off: an off copy goes, or stands in for a missing original
        if (section === "off" && uid !== w.id) {
            if (originals[w.id])
                return;
            uid = w.id;
            originals[w.id] = true;
        }
        if (seenUid[uid])
            return;
        seenUid[uid] = true;
        seenId[w.id] = true;
        var entry = { uid: uid, id: w.id, section: section };
        // the card's own colour (2026-10-29; none = the global theme.card)
        if (DCatalog.CARDS.indexOf(w.cardColor) >= 0)
            entry.cardColor = w.cardColor;
        var renamed = RENAMED_STYLES[w.id] || {};
        WIDGET_MODES.forEach(function (m) {
            var style = w[m];
            if (renamed[style])
                style = renamed[style];
            entry[m] = Catalog.validStyle(w.id, style) ? style : d[m];
        });
        out.push(entry);
    });

    defaults.forEach(function (d) {
        if (!seenUid[d.id])
            out.push({ uid: d.id, id: d.id, section: seenId[d.id] ? "off" : d.section, compact: d.compact, expanded: d.expanded });
    });
    return out;
}

// Dashboard entries (dwidgets/README.md). Unknown ids and duplicate uids are dropped; an invalid
// style, size, position, off flag or options object falls back to the catalog's.
// Off keeps one entry per Dwidget: a second off entry with the same id is dropped.
// Every catalog Dwidget with no entry at all (except `debug` ones) is appended as an off entry,
// so the Off area always offers it. Overlaps are left to the layout engine.
function mergeDashboard(user, defaults) {
    if (typeOf(user) !== "array")
        return clone(defaults);

    var seen = {};
    var out = [];
    var uidOf = function (w) {
        return typeOf(w.uid) === "string" && w.uid !== "" ? w.uid : w.id;
    };
    // only the original (uid = id) may be off (2026-10-11, as the island): an off copy goes, or stands
    // in for a missing original
    var originals = {};
    user.forEach(function (w) {
        if (typeOf(w) === "object" && DCatalog.has(w.id) && uidOf(w) === w.id)
            originals[w.id] = true;
    });
    user.forEach(function (w) {
        if (typeOf(w) !== "object" || !DCatalog.has(w.id))
            return;
        var uid = uidOf(w);
        if (w.off === true && uid !== w.id) {
            if (originals[w.id])
                return;
            uid = w.id;
            originals[w.id] = true;
        }
        if (seen[uid])
            return;
        seen[uid] = true;
        var d = DCatalog.defaultEntry(w.id, uid, 0, 0);
        var idleIn = typeOf(w.idle) === "object" ? w.idle : {};
        var options = typeOf(w.options) === "object" ? w.options : d.options;
        if (typeOf(idleIn) === "object" && DCatalog.renamed)
            idleIn = Object.assign({}, idleIn, { style: DCatalog.renamed(w.id, idleIn.style) });
        var idle = DCatalog.validMode(w.id, idleIn, d.idle);
        var cell = function (v) {
            return typeOf(v) === "number" && v >= 0 ? Math.floor(v) : 0;
        };
        out.push({
            uid: uid,
            id: w.id,
            idle: idle,
            x: cell(w.x),
            y: cell(w.y),
            off: w.off === true,
            options: options
        });
        // the expand event, only for a Dwidget that expands (else it's the catalog's: none)
        if (DCatalog.hasEvent(w.id) && DCatalog.TRIGGERS.indexOf(w.expandOn) >= 0)
            out[out.length - 1].expandOn = w.expandOn;
    });

    // every Dwidget has its original (Off always offers it), e.g. when only copies are left
    Object.keys(DCatalog.WIDGETS).forEach(function (id) {
        if (DCatalog.WIDGETS[id].debug || seen[id])
            return;
        var e = DCatalog.defaultEntry(id, id, 0, 0);
        e.off = true;
        out.push(e);
    });
    return out;
}

// JSON with sorted keys, so key order never counts as a difference
function canonical(v) {
    if (typeOf(v) === "array")
        return "[" + v.map(canonical).join(",") + "]";
    if (typeOf(v) === "object")
        return "{" + Object.keys(v).sort().map(function (k) {
            return JSON.stringify(k) + ":" + canonical(v[k]);
        }).join(",") + "}";
    return JSON.stringify(v);
}

// `v` with only the keys `d` knows, recursively (what a JsonAdapter keeps). Maps whose default is {}
// (the color mappings, options) and arrays stay whole. Presets compare files with it.
function known(v, d) {
    if (typeOf(v) !== "object" || typeOf(d) !== "object" || Object.keys(d).length === 0)
        return v;
    var out = {};
    for (var k in d)
        if (k in v)
            out[k] = known(v[k], d[k]);
    return out;
}

function merge(user, defaults, path) {
    path = path || "";

    if (path === "island.widgets")
        return mergeWidgets(user, defaults);
    if (path === "dashboard.widgets")
        return mergeDashboard(user, defaults);
    // the schema version is always the current one
    if (path === "version")
        return defaults;
    // the color mappings: known tokens with string specs only (bad specs fall back when resolved)
    if (path === "theme.colors.dark" || path === "theme.colors.light")
        return ColorRoles.clean(user);

    if (typeOf(defaults) === "object") {
        var u = typeOf(user) === "object" ? user : {};
        var out = {};
        for (var k in u)
            out[k] = u[k];
        for (var key in defaults)
            out[key] = merge(u[key], defaults[key], path ? path + "." + key : key);
        return out;
    }

    if (typeOf(user) !== typeOf(defaults))
        return clone(defaults);
    if (ENUMS[path] && ENUMS[path].indexOf(user) < 0)
        return defaults;
    return user;
}
