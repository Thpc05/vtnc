.pragma library
.import "../iwidgets/catalog.js" as Catalog
.import "../dwidgets/catalog.js" as DCatalog
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
// Iwidget styles renamed (old → new), kept instead of falling back to the default
var RENAMED_STYLES = {
    // the chevron, then the "compact" style, became Icons + island.tray.<mode>.fold (2026-10-11, set below)
    tray: { mono: "tint", chevron: "icons", pill: "iconsCard", compact: "icons", compactCard: "iconsCard" },
    // the app icons style became Pagination (2026-10-09; its app icons option went 2026-10-15)
    // Shapes went (2026-10-15): it became how Two tones / Tone show the windows (island.workspaces.windows)
    workspaces: { icons: "pagination", iconsCard: "paginationCard", shapes: "tones", shapesCard: "tonesCard" },
    // the dock's Shapes went (2026-10-15)
    dock: { shapes: "icons", shapesCard: "iconsCard" },
    // the media "Card" became Default + its Card variant (2026-10-09); Controls became an option of every
    // style (2026-10-15; island.media.<mode>.controls, set below)
    media: { title: "defaultCard", controls: "default", controlsCard: "defaultCard" },
    // the active window's "category" became "tone" (2026-10-11)
    window: { category: "tone", categoryCard: "toneCard" },
    // upright, text and then Default went (2026-10-11): Shapes (text alone = island.battery.<mode>.show,
    // set below)
    battery: { upright: "shapes", text: "shapes", default: "shapes", defaultCard: "shapesCard" },
    // one volume style (2026-10-11, user): the icon and the percent became options (set below); "slider"
    // stays an id (the old Slider alone migrates by its options)
    volume: { pill: "slider", iconSlider: "slider", iconSliderCard: "sliderCard" }
};

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

// Widgets are entries with a `uid` (2026-10-11: an Iwidget may be on the island more than once, as the
// Dwidgets; old entries get uid = id). The original is uid = id, its copies `<id>-2`…: only the
// original may be in Off (an off copy is dropped, or becomes the original when there's none). Unknown
// ids and duplicate uids are dropped. An Iwidget without its original gets one: its factory entry
// when it has no entry at all (a new widget), else an off one (Off always offers each Iwidget). Styles are checked against
// the iwidget catalog.
// Migrates the old model: mode off/on/show/hidden (state v3 and older) → compact/expanded styles.
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
        var section = w.mode === "off" ? "off" : (WIDGET_SECTIONS.indexOf(w.section) >= 0 ? w.section : d.section);
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
        var renamed = RENAMED_STYLES[w.id] || {};
        WIDGET_MODES.forEach(function (m) {
            var style = w[m];
            if (style === undefined && w.mode !== undefined) {
                // old model: "hidden" = only while expanded, anything else = always
                style = m === "compact" && w.mode === "hidden" ? Catalog.HIDDEN : Catalog.defaultStyle(w.id, m);
            }
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
// Quick configs once had options.layout (the size arranges it now): it goes. Old style ids (its
// arrangements, the expressive looks…) need nothing: an unknown style falls back to the catalog's.
function migrateQuick(options) {
    if (typeOf(options) === "object" && "layout" in options) {
        options = Object.assign({}, options);
        delete options.layout;
    }
    return options;
}

// The theme's absolute sizes (roundness px, fontSize px, anim.duration ms) became scales (2026-10-08,
// caelestia's appearance.*.scale): 1 = the factory look (16 px, 14 px, 450 ms). The old keys go.
function migrateTheme(theme) {
    if (typeOf(theme) !== "object")
        return theme;
    var anim = typeOf(theme.anim) === "object" ? theme.anim : null;
    var old = "roundness" in theme || "fontSize" in theme || (anim && "duration" in anim);
    if (!old)
        return theme;
    var t = clone(theme);
    var a = typeOf(t.anim) === "object" ? t.anim : null;
    if (typeOf(t.scale) !== "object") {
        var ratio = function (v, base) {
            return typeOf(v) === "number" && v >= 0 ? Math.round(v / base * 20) / 20 : 1;
        };
        t.scale = {
            rounding: ratio(t.roundness, 16),
            spacing: 1,
            padding: 1,
            font: typeOf(t.fontSize) === "number" && t.fontSize > 0 ? ratio(t.fontSize, 14) : 1,
            anim: ratio(a ? a.duration : undefined, 450)
        };
    }
    delete t.roundness;
    delete t.fontSize;
    if (a)
        delete a.duration;
    return t;
}

// The screen corners became caelestia's frame (2026-10-08): `corners` {enabled, size} → `frame`
// {enabled, thickness, rounding} at the frame's factory look (corners only = thickness 0).
function migrateFrame(file, defaults) {
    if (typeOf(file) !== "object" || !("corners" in file) || typeOf(defaults) !== "object" || !("frame" in defaults))
        return file;
    var f = clone(file);
    if (typeOf(f.frame) !== "object") {
        f.frame = clone(defaults.frame);
        if (typeOf(f.corners) === "object" && f.corners.enabled === false)
            f.frame.enabled = false;
    }
    delete f.corners;
    return f;
}

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
        // old shape (one style / size): that's the idle mode
        var idleIn = typeOf(w.idle) === "object" ? w.idle : { style: w.style, size: w.size };
        var options = typeOf(w.options) === "object" ? w.options : d.options;
        if (w.id === "quick")
            options = migrateQuick(options);
        // (expanded looks are gone: a Dwidget that needs to expand does so in its own style)
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
    // the schema version is always the current one (migrations above have already run)
    if (path === "version")
        return defaults;
    // the color mappings: known tokens with string specs only (bad specs fall back when resolved)
    if (path === "theme.colors.dark" || path === "theme.colors.light")
        return ColorRoles.clean(user);
    if (path === "theme")
        user = migrateTheme(user);
    // Random shapes became an option of each Dwidget (2026-10-17; a day as dashboard.randomShapes): a
    // global off goes into every entry's options that has none
    if (path === "dashboard" && typeOf(user) === "object" && "randomShapes" in user) {
        user = clone(user);
        if (user.randomShapes === false && typeOf(user.widgets) === "array")
            user.widgets = user.widgets.map(function (w) {
                if (typeOf(w) !== "object" || !DCatalog.has(w.id))
                    return w;
                var o = typeOf(w.options) === "object" ? w.options : DCatalog.defaultEntry(w.id, w.id, 0, 0).options;
                if ("randomShapes" in o)
                    return w;
                return Object.assign({}, w, { options: Object.assign({}, o, { randomShapes: false }) });
            });
        delete user.randomShapes;
    }
    if (path === "")
        user = migrateFrame(user, defaults);
    // the media options became per island mode (2026-10-09): the flat ones go to both modes
    if (path === "island" && typeOf(user) === "object" && typeOf(user.media) === "object" && "showArt" in user.media && !("compact" in user.media)) {
        user = clone(user);
        var flat = {};
        ["showArt", "showTitle", "showArtist", "showWave"].forEach(function (k) {
            if (k in user.media)
                flat[k] = user.media[k];
        });
        user.media = { compact: clone(flat), expanded: clone(flat) };
    }
    // the anchors became per island mode (2026-10-15): the flat ones (and island.anchorCenter) go to both
    if (path === "island" && typeOf(user) === "object" && ("anchorCenter" in user || (typeOf(user.anchors) === "object" && !("compact" in user.anchors) && !("expanded" in user.anchors)))) {
        user = clone(user);
        var flatAnchors = typeOf(user.anchors) === "object" ? clone(user.anchors) : {};
        if ("anchorCenter" in user)
            flatAnchors.anchorCenter = user.anchorCenter;
        delete user.anchorCenter;
        user.anchors = { compact: clone(flatAnchors), expanded: clone(flatAnchors) };
    }
    // the media's Controls style became the controls option per mode (2026-10-15): on where it was used,
    // before the rename
    if (path === "island" && typeOf(user) === "object" && Array.isArray(user.widgets)) {
        var withControls = {};
        user.widgets.forEach(function (w) {
            if (w && w.id === "media")
                WIDGET_MODES.forEach(function (m) {
                    if (w[m] === "controls" || w[m] === "controlsCard")
                        withControls[m] = true;
                });
        });
        if (Object.keys(withControls).length > 0) {
            user = clone(user);
            user.media = Object.assign({}, typeOf(user.media) === "object" ? user.media : {});
            Object.keys(withControls).forEach(function (m) {
                user.media[m] = Object.assign({}, typeOf(user.media[m]) === "object" ? user.media[m] : {}, { controls: true });
            });
        }
    }
    // the active window's short title became the text option per mode (2026-10-11): on = "first"
    if (path === "island" && typeOf(user) === "object" && typeOf(user.window) === "object" && "shortTitle" in user.window) {
        user = clone(user);
        if (user.window.shortTitle === true)
            WIDGET_MODES.forEach(function (m) {
                user.window[m] = Object.assign({}, typeOf(user.window[m]) === "object" ? user.window[m] : {}, { text: "first" });
            });
        delete user.window.shortTitle;
    }
    // the battery's text style became `show: text` (2026-10-11): per mode, before the rename
    if (path === "island" && typeOf(user) === "object" && Array.isArray(user.widgets) && !("battery" in user)) {
        var texts = {};
        user.widgets.forEach(function (w) {
            if (w && w.id === "battery")
                WIDGET_MODES.forEach(function (m) {
                    if (w[m] === "text")
                        texts[m] = true;
                });
        });
        if (Object.keys(texts).length > 0) {
            user = clone(user);
            user.battery = {};
            Object.keys(texts).forEach(function (m) {
                user.battery[m] = { show: "text" };
            });
        }
    }
    // the tray's fold was a bool for a moment (2026-10-11): on = "right" (the chevron before the icons)
    if (path === "island" && typeOf(user) === "object" && typeOf(user.tray) === "object" && WIDGET_MODES.some(function (m) {
        return typeOf(user.tray[m]) === "object" && typeof user.tray[m].fold === "boolean";
    })) {
        user = clone(user);
        WIDGET_MODES.forEach(function (m) {
            if (typeOf(user.tray[m]) === "object" && typeof user.tray[m].fold === "boolean")
                user.tray[m].fold = user.tray[m].fold ? "right" : "off";
        });
    }
    // the tray's compact style became the fold option (2026-10-11): per mode, before the rename (the old
    // chevron sat before the icons: "right")
    if (path === "island" && typeOf(user) === "object" && Array.isArray(user.widgets) && !(typeOf(user.tray) === "object" && ("compact" in user.tray || "expanded" in user.tray))) {
        var folds = {};
        user.widgets.forEach(function (w) {
            if (w && w.id === "tray")
                WIDGET_MODES.forEach(function (m) {
                    if (["compact", "compactCard", "chevron"].indexOf(w[m]) >= 0)
                        folds[m] = true;
                });
        });
        if (Object.keys(folds).length > 0) {
            user = clone(user);
            user.tray = Object.assign({}, typeOf(user.tray) === "object" ? user.tray : {});
            Object.keys(folds).forEach(function (m) {
                user.tray[m] = { fold: "right" };
            });
        }
    }
    // one volume style (2026-10-11): the old Slider alone = no icon, no percent in that mode
    if (path === "island" && typeOf(user) === "object" && Array.isArray(user.widgets) && !("volume" in user)) {
        var bare = {};
        user.widgets.forEach(function (w) {
            if (w && w.id === "volume")
                WIDGET_MODES.forEach(function (m) {
                    if (w[m] === "slider" || w[m] === "sliderCard")
                        bare[m] = true;
                });
        });
        if (Object.keys(bare).length > 0) {
            user = clone(user);
            user.volume = {};
            Object.keys(bare).forEach(function (m) {
                user.volume[m] = { icon: false, percent: false };
            });
        }
    }
    // the tray's mono became tint (2026-10-09): its colour key follows
    if (path === "island" && typeOf(user) === "object" && typeOf(user.tray) === "object" && "monoColor" in user.tray && !("tintColor" in user.tray)) {
        user = clone(user);
        user.tray.tintColor = user.tray.monoColor === "default" ? "surface" : user.tray.monoColor;
        delete user.tray.monoColor;
    }
    // the date became its own Iwidget (2026-10-08): the clock's dateFormat moves to island.date
    if (path === "island" && typeOf(user) === "object" && typeOf(user.clock) === "object" && "dateFormat" in user.clock) {
        user = clone(user);
        if (typeOf(user.date) !== "object")
            user.date = { format: user.clock.dateFormat };
        delete user.clock.dateFormat;
    }
    // the frame and the rounded corners became independent (2026-10-08): "thickness 0" meant
    // corners only, now the frame's own switch
    if (path === "frame" && typeOf(user) === "object" && user.enabled === true && user.thickness === 0 && !("roundCorners" in user)) {
        user = clone(user);
        user.enabled = false;
        user.thickness = defaults.thickness;
    }

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
