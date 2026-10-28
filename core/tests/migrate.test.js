// Tests for core/Migrate.js (the one-file state split into core/STATE.md's files) and the
// StateMerge helpers Presets uses. Run: node core/tests/migrate.test.js
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const root = path.join(__dirname, "..", "..");
const strip = f => fs.readFileSync(path.join(root, f), "utf8").replace(/^\.(pragma|import).*$/mg, "");
const lib = (f, names, args = [], vals = []) => new Function(...args, strip(f) + "\nreturn {" + names.join(",") + "};")(...vals);

const Catalog = lib("iwidgets/catalog.js", ["WIDGETS", "HIDDEN", "has", "validStyle", "defaultStyle", "baseStyle", "isCard", "cardVariant", "parents"]);
const DCatalog = lib("dwidgets/catalog.js", ["WIDGETS", "MODES", "CARDS", "TRIGGERS", "has", "style", "validStyle", "validSize", "parseSize", "validMode", "expandedSize", "trigger", "expands", "hasEvent", "defaultEntry", "renamed", "baseStyle", "isCard"]);
const ColorRoles = lib("theme/colorRoles.js", ["clean", "TOKENS"]);
const M = lib("core/StateMerge.js", ["merge", "canonical", "known"], ["Catalog", "DCatalog", "ColorRoles"], [Catalog, DCatalog, ColorRoles]);
const Migrate = lib("core/Migrate.js", ["split", "FILES"]);

const FILES = { island: "config/island", dashboard: "config/dashboard", appearance: "config/appearance", system: "config/system", state: "state" };
const factory = {};
for (const k in FILES)
    factory[k] = JSON.parse(fs.readFileSync(path.join(root, "defaults", FILES[k] + ".json"), "utf8"));

// an old (schema 4) state: the factory values in the old shape, with a few changes
const old = {
    version: 4,
    island: Object.assign({}, factory.island.island, { hoverDelay: 99 }),
    osd: factory.island.osd,
    dashboard: factory.dashboard.dashboard,
    theme: Object.assign({}, factory.appearance.theme, { scheme: "scheme-content", colors: { dark: { primary: "light:primary" }, light: {} } }),
    corners: { enabled: true, size: 20 },
    wallpaper: { dir: "~/Walls", current: "/w/a.jpg", transition: "fade" },
    tools: factory.system.tools,
    audio: factory.system.audio,
    controls: { nightLight: true, nightLightTemp: 3800, caffeine: false, gameMode: false, dnd: true },
    media: { enableFirefoxPlayer: false, player: "Spotify" },
    apps: { tools: { showHints: false }, session: { showHints: true, x: 1 }, settings: { path: "island/osd" } }
};

let failed = 0, passed = 0;
function test(name, fn) {
    try {
        fn();
        passed++;
    } catch (e) {
        failed++;
        console.log("FAIL " + name + "\n  " + e.message);
    }
}

const parts = Migrate.split(old);
const merged = {};
for (const k in FILES)
    merged[k] = M.merge(parts[k], factory[k]);

test("every file is produced", () => {
    assert.deepStrictEqual(Object.keys(parts).sort(), Migrate.FILES.slice().sort());
});
test("every old top-level key lands in exactly one file", () => {
    const moved = { controls: 1, media: 1, wallpaper: 1, apps: 1 };  // split across files
    for (const k in old) {
        if (k === "version" || moved[k])
            continue;
        const where = Object.keys(parts).filter(f => k in parts[f]);
        assert.strictEqual(where.length, 1, k + " in " + where);
    }
});
test("values survive", () => {
    assert.strictEqual(merged.island.island.hoverDelay, 99);
    assert.strictEqual(merged.appearance.theme.scheme, "scheme-content");
    assert.deepStrictEqual(merged.appearance.theme.colors.dark, { primary: "light:primary" });
    assert.strictEqual(merged.appearance.wallpaper.current, "/w/a.jpg");
});
test("renames", () => {
    assert.deepStrictEqual(merged.system.wallpapers, { dir: "~/Walls", transition: "fade" });
    assert.strictEqual(merged.system.nightLight.temp, 3800);
    assert.strictEqual(merged.system.media.enableFirefoxPlayer, false);
    assert.deepStrictEqual(merged.system.hints, { tools: false, session: true });
    assert.strictEqual(merged.state.player.pinned, "Spotify");
    assert.deepStrictEqual(merged.state.controls, { nightLight: true, caffeine: false, gameMode: false, dnd: true });
    assert.deepStrictEqual(merged.state.apps, { session: { x: 1 }, settings: { path: "island/osd" } });
    assert.strictEqual(merged.state.version, factory.state.version);
});
test("the old input isn't changed", () => {
    assert.strictEqual(old.controls.nightLightTemp, 3800);
    assert.strictEqual(old.apps.tools.showHints, false);
});
test("an empty or broken state gives the factory files", () => {
    for (const bad of [null, {}, "x"]) {
        const p = Migrate.split(bad);
        for (const k in FILES)
            assert.strictEqual(M.canonical(M.merge(p[k], factory[k])), M.canonical(factory[k]), k);
    }
});
test("a factory-shaped old state migrates to the factory files", () => {
    const f = {
        island: factory.island.island, osd: factory.island.osd, dashboard: factory.dashboard.dashboard,
        theme: factory.appearance.theme, corners: { enabled: true, size: 20 },
        wallpaper: { dir: factory.system.wallpapers.dir, transition: factory.system.wallpapers.transition, current: "" },
        tools: factory.system.tools, audio: factory.system.audio,
        controls: Object.assign({ nightLightTemp: factory.system.nightLight.temp }, factory.state.controls),
        media: { enableFirefoxPlayer: factory.system.media.enableFirefoxPlayer, player: "" },
        apps: { tools: { showHints: true }, session: { showHints: true } }
    };
    const p = Migrate.split(f);
    for (const k in FILES)
        assert.strictEqual(M.canonical(M.merge(p[k], factory[k])), M.canonical(factory[k]), k);
});
test("known drops unknown keys, keeps maps and arrays", () => {
    const d = { a: 1, o: { x: 1 }, map: {}, list: [] };
    const v = { a: 2, stray: 1, o: { x: 2, y: 3 }, map: { k: "v" }, list: [{ z: 1 }] };
    assert.deepStrictEqual(M.known(v, d), { a: 2, o: { x: 2 }, map: { k: "v" }, list: [{ z: 1 }] });
});

test("the theme's absolute sizes become scales", () => {
    const t = Object.assign({}, factory.appearance.theme, { roundness: 24, fontSize: 14, anim: { duration: 0, bounce: 3 } });
    delete t.scale;
    const m = M.merge({ theme: t }, factory.appearance).theme;
    assert.deepStrictEqual(m.scale, { rounding: 1.5, spacing: 1, padding: 1, font: 1, anim: 0 });
    assert.ok(!("roundness" in m) && !("fontSize" in m) && !("duration" in m.anim));
    assert.strictEqual(t.roundness, 24, "input unchanged");
});
test("an existing scale wins over old keys", () => {
    const t = Object.assign({}, factory.appearance.theme, { roundness: 32, scale: Object.assign({}, factory.appearance.theme.scale, { rounding: 0.5 }) });
    assert.strictEqual(M.merge({ theme: t }, factory.appearance).theme.scale.rounding, 0.5);
});

test("screen corners become the frame", () => {
    const a = Object.assign({}, factory.appearance, { corners: { enabled: false, size: 12 } });
    delete a.frame;
    const m = M.merge(a, factory.appearance);
    assert.ok(!("corners" in m));
    assert.deepStrictEqual(m.frame, Object.assign({}, factory.appearance.frame, { enabled: false }));
    const b = Object.assign({}, factory.appearance, { corners: { enabled: true, size: 12 } });
    delete b.frame;
    assert.deepStrictEqual(M.merge(b, factory.appearance).frame, factory.appearance.frame);
});

test("a zero-thickness frame becomes corners only", () => {
    const a = Object.assign({}, factory.appearance, { frame: { enabled: true, thickness: 0, rounding: 24 } });
    const f = M.merge(a, factory.appearance).frame;
    assert.deepStrictEqual(f, { enabled: false, thickness: factory.appearance.frame.thickness, rounding: 24, roundCorners: true });
});

test("the clock's date format moves to the date Iwidget", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.clock = { font: "", weight: 600, size: 0, letterSpacing: 0, timeFormat: "HH:mm", dateFormat: "dd/MM" };
    delete island.island.date;
    island.island.widgets = island.island.widgets.filter(w => w.id !== "date").map(w => w.id === "clock" ? Object.assign({}, w, { expanded: "timeDate" }) : w);
    const m = M.merge(island, factory.island).island;
    assert.ok(!("dateFormat" in m.clock));
    assert.strictEqual(m.date.format, "dd/MM");
    assert.strictEqual(m.date.color, factory.island.island.date.color);
    // the old style falls back; the date entry comes from the factory list
    assert.strictEqual(m.widgets.find(w => w.id === "clock").expanded, "time");
    assert.ok(m.widgets.some(w => w.id === "date"));
    assert.strictEqual(M.merge(Object.assign({}, island, { island: Object.assign({}, island.island, { clock: Object.assign({}, island.island.clock, { color: "pink" }) }) }), factory.island).island.clock.color, "default");
});

test("Iwidget card variants: base, card flag, parents, validation", () => {
    assert.strictEqual(Catalog.baseStyle("workspaces", "toneCard"), "tone");
    assert.strictEqual(Catalog.baseStyle("workspaces", "tone"), "tone");
    assert.ok(Catalog.isCard("clock", "timeCard"));
    assert.ok(!Catalog.isCard("clock", "time"));
    assert.strictEqual(Catalog.cardVariant("volume", "slider"), "sliderCard");
    assert.ok(Catalog.parents("media").every(s => !s.group));
    assert.ok(Catalog.validStyle("media", "tonesCard"));
    assert.ok(!Catalog.validStyle("media", "wavy"));
});

test("old Iwidget styles fall back; the counts validate", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.tray = { tintColor: "pink" };
    island.island.workspaces = { compactCount: "x", expandedCount: 7 };
    island.island.widgets = island.island.widgets.map(w => w.id === "workspaces" ? Object.assign({}, w, { compact: "pills", expanded: "tonesCard" }) : w.id === "tray" ? Object.assign({}, w, { expanded: "chevron" }) : w);
    const m = M.merge(island, factory.island).island;
    assert.ok(!("card" in m));
    assert.strictEqual(m.tray.tintColor, "primary");
    assert.deepStrictEqual(m.workspaces, { compactCount: 0, expandedCount: 7, label: "number", focus: "pill", windows: { compact: "off", expanded: "icons", max: 3 } });
    const ws = m.widgets.find(w => w.id === "workspaces");
    assert.strictEqual(ws.compact, factory.island.island.widgets.find(w => w.id === "workspaces").compact);
    assert.strictEqual(ws.expanded, "tonesCard");
    // renamed styles carry over
    assert.strictEqual(m.widgets.find(w => w.id === "tray").expanded, "icons");
    assert.deepStrictEqual([m.tray.compact.fold, m.tray.expanded.fold], ["off", "right"]);
    const old = JSON.parse(JSON.stringify(factory.island));
    old.island.tray = { monoColor: "default" };
    old.island.widgets = old.island.widgets.map(w => w.id === "tray" ? Object.assign({}, w, { expanded: "mono" }) : w);
    const o = M.merge(old, factory.island).island;
    assert.strictEqual(o.widgets.find(w => w.id === "tray").expanded, "tint");
    assert.deepStrictEqual(o.tray, { tintColor: "surface", compact: { fold: "off" }, expanded: { fold: "off" } });
    const pill = JSON.parse(JSON.stringify(factory.island));
    pill.island.widgets = pill.island.widgets.map(w => w.id === "tray" ? Object.assign({}, w, { expanded: "pill" }) : w);
    assert.strictEqual(M.merge(pill, factory.island).island.widgets.find(w => w.id === "tray").expanded, "iconsCard");
    assert.ok(m.widgets.some(w => w.id === "quick" && w.section === "off"));
});

test("the workspaces' icons style becomes pagination; the app icons option is gone", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    delete island.island.workspaces;
    island.island.widgets = island.island.widgets.map(w => w.id === "workspaces" ? Object.assign({}, w, { compact: "hidden", expanded: "iconsCard" }) : w);
    const m = M.merge(island, factory.island).island;
    assert.strictEqual(m.widgets.find(w => w.id === "workspaces").expanded, "paginationCard");
    assert.ok(!("appIcons" in m.workspaces));
});

test("the flat media options go to both island modes", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.media = { showArt: false, showTitle: true, showArtist: true, showWave: false };
    const m = M.merge(island, factory.island).island.media;
    assert.strictEqual(m.compact.showArt, false);
    assert.strictEqual(m.expanded.showArt, false);
    assert.strictEqual(m.expanded.showWave, false);
    assert.strictEqual(m.compact.width, 0);
});

test("the media Card style becomes Default + Card; Controls becomes the controls option", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.widgets = island.island.widgets.map(w => w.id === "media" ? Object.assign({}, w, { compact: "title", expanded: "controlsCard" }) : w);
    island.island.media.compact.controls = false;
    island.island.media.expanded.controls = false;
    const merged = M.merge(island, factory.island).island;
    const media = merged.widgets.find(w => w.id === "media");
    assert.strictEqual(media.compact, "defaultCard");
    assert.strictEqual(media.expanded, "defaultCard");
    assert.strictEqual(merged.media.compact.controls, false);
    assert.strictEqual(merged.media.expanded.controls, true);
});

test("the visualizer: added off for old configs, colour enum, card variants", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.widgets = island.island.widgets.filter(w => w.id !== "visualizer");
    island.island.visualizer = { color: "pink" };
    const m = M.merge(island, factory.island).island;
    assert.ok(m.widgets.some(w => w.id === "visualizer" && w.section === "off"));
    assert.strictEqual(m.visualizer.color, "primary");
    assert.strictEqual(m.visualizer.expanded.bars, 24);
    assert.ok(Catalog.validStyle("visualizer", "shapesCard"));
    assert.ok(!Catalog.validStyle("visualizer", "blob"));
});

test("the active window: added off for old configs, its options, card variants; visualizer min height", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.widgets = island.island.widgets.filter(w => w.id !== "window");
    delete island.island.window;
    island.island.visualizer = { compact: { bars: 8 } };
    const m = M.merge(island, factory.island).island;
    assert.ok(m.widgets.some(w => w.id === "window" && w.section === "off"));
    assert.strictEqual(m.window.expanded.maxWidth, 280);
    assert.strictEqual(m.window.compact.text, "both");
    assert.strictEqual(m.window.compact.showIcon, true);
    island.island.window = { shortTitle: true, expanded: { maxWidth: 300 } };
    const w = M.merge(island, factory.island).island.window;
    assert.ok(!("shortTitle" in w));
    assert.strictEqual(w.compact.text, "first");
    assert.strictEqual(w.expanded.text, "first");
    assert.strictEqual(w.expanded.maxWidth, 300);
    island.island.window = { compact: { text: "middle" } };
    assert.strictEqual(M.merge(island, factory.island).island.window.compact.text, "both");
    assert.strictEqual(m.visualizer.compact.minHeight, 2);
    assert.ok(Catalog.validStyle("window", "toneCard"));
    island.island.widgets = island.island.widgets.concat([{ id: "window", section: "left", compact: "category", expanded: "categoryCard" }]);
    const win = M.merge(island, factory.island).island.widgets.find(w => w.id === "window");
    assert.strictEqual(win.compact, "tone");
    assert.strictEqual(win.expanded, "toneCard");
});

test("island widgets: uids, repeats on the island, one per Iwidget in Off", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    const clock = island.island.widgets.find(w => w.id === "clock");
    island.island.widgets = island.island.widgets.map(w => { const c = Object.assign({}, w); delete c.uid; return c; })
        .concat([Object.assign({}, clock, { uid: "clock-2", section: "left" }), Object.assign({}, clock, { uid: "clock-2" }),
            { uid: "battery-2", id: "battery", section: "off", compact: "text", expanded: "text" }]);
    const ws = M.merge(island, factory.island).island.widgets;
    // old entries: uid = id
    assert.strictEqual(ws.find(w => w.id === "workspaces").uid, "workspaces");
    // a second clock on the island; a duplicate uid is dropped
    assert.strictEqual(ws.filter(w => w.id === "clock").length, 2);
    assert.strictEqual(ws.find(w => w.uid === "clock-2").section, "left");
    // only the original may be off: an off copy goes
    assert.strictEqual(ws.filter(w => w.id === "battery").length, 1);
    assert.strictEqual(ws.find(w => w.id === "battery").uid, "battery");
    // a lone off copy stands in for the original; copies without an original get an off one
    const lone = JSON.parse(JSON.stringify(factory.island));
    lone.island.widgets = lone.island.widgets.filter(w => w.id !== "quick" && w.id !== "clock")
        .concat([{ uid: "quick-2", id: "quick", section: "off", compact: "shapes", expanded: "shapes" },
            { uid: "clock-3", id: "clock", section: "left", compact: "time", expanded: "time" }]);
    const ls = M.merge(lone, factory.island).island.widgets;
    assert.deepStrictEqual(ls.filter(w => w.id === "quick").map(w => [w.uid, w.section]), [["quick", "off"]]);
    assert.deepStrictEqual(ls.filter(w => w.id === "clock").map(w => [w.uid, w.section]), [["clock-3", "left"], ["clock", "off"]]);
});

test("the island apps' options: system apps.*", () => {
    const system = JSON.parse(JSON.stringify(factory.system));
    delete system.apps;
    assert.deepStrictEqual(M.merge(system, factory.system).apps, factory.system.apps);
    system.apps = { notes: { format: "rich" }, dino: { speed: "warp" }, notifications: { maxAgeDays: 3 } };
    const m = M.merge(system, factory.system).apps;
    assert.strictEqual(m.notes.format, "markdown");
    assert.strictEqual(m.dino.speed, "normal");
    assert.strictEqual(m.notifications.maxAgeDays, 0);
    assert.strictEqual(m.clipboard.maxItems, 750);
});

test("the apps' look: theme.appStyle", () => {
    const appearance = JSON.parse(JSON.stringify(factory.appearance));
    appearance.theme.appStyle = "round";
    assert.strictEqual(M.merge(appearance, factory.appearance).theme.appStyle, "shapes");
    appearance.theme.appStyle = "tone";
    assert.strictEqual(M.merge(appearance, factory.appearance).theme.appStyle, "tone");
});

test("one card colour for the island and the dashboard: theme.card", () => {
    const appearance = JSON.parse(JSON.stringify(factory.appearance));
    appearance.theme.card = "pink";
    assert.strictEqual(M.merge(appearance, factory.appearance).theme.card, "neutral");
    appearance.theme.card = "tinted";
    assert.strictEqual(M.merge(appearance, factory.appearance).theme.card, "tinted");
});

test("battery: upright, text and Default became Shapes, text alone its show option; the volume OSD as its widget", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    delete island.island.battery;
    delete island.osd.volumeWidget;
    island.island.widgets = island.island.widgets.filter(w => w.id !== "battery")
        .concat([{ uid: "battery", id: "battery", section: "right", compact: "text", expanded: "upright" }]);
    const m = M.merge(island, factory.island);
    const b = m.island.widgets.find(w => w.id === "battery");
    assert.deepStrictEqual([b.compact, b.expanded], ["shapes", "shapes"]);
    assert.strictEqual(m.island.battery.compact.show, "text");
    assert.strictEqual(m.island.battery.expanded.show, "both");
    assert.strictEqual(m.island.battery.color, "primary");
    assert.strictEqual(m.osd.volumeWidget, false);
    // an existing battery block isn't touched; bad values fall back
    island.island.battery = { color: "pink", compact: { show: "icon" }, expanded: { show: "nope" } };
    const m2 = M.merge(island, factory.island).island.battery;
    assert.deepStrictEqual([m2.color, m2.compact.show, m2.expanded.show], ["primary", "icon", "both"]);
    assert.ok(Catalog.validStyle("battery", "ringCard"));
    assert.ok(Catalog.validStyle("battery", "arcCard"));
    // one volume style: pill / Icon + slider → slider; the old Slider alone → no icon / percent there
    delete island.island.volume;
    island.island.widgets = island.island.widgets.map(w => w.id === "volume" ? Object.assign({}, w, { compact: "pill", expanded: "sliderCard" }) : w);
    const vm = M.merge(island, factory.island).island;
    const v = vm.widgets.find(w => w.id === "volume");
    assert.deepStrictEqual([v.compact, v.expanded], ["slider", "sliderCard"]);
    assert.deepStrictEqual(vm.volume, { wavy: true, compact: { icon: true, percent: true }, expanded: { icon: false, percent: false } });
    island.island.widgets = island.island.widgets.map(w => w.id === "volume" ? Object.assign({}, w, { compact: "iconSliderCard" }) : w);
    assert.strictEqual(M.merge(island, factory.island).island.widgets.find(w => w.id === "volume").compact, "sliderCard");
    // the tray's compact style → Icons / Icons + Card folded in that mode
    const t = JSON.parse(JSON.stringify(factory.island));
    delete t.island.tray;
    t.island.widgets = t.island.widgets.map(w => w.id === "tray" ? Object.assign({}, w, { compact: "compact", expanded: "compactCard" }) : w);
    const tm = M.merge(t, factory.island).island;
    const tw = tm.widgets.find(w => w.id === "tray");
    assert.deepStrictEqual([tw.compact, tw.expanded], ["icons", "iconsCard"]);
    assert.deepStrictEqual([tm.tray.compact.fold, tm.tray.expanded.fold], ["right", "right"]);
    // the bool of a moment, and bad values
    t.island.tray = { compact: { fold: true }, expanded: { fold: "up" } };
    const tb = M.merge(t, factory.island).island.tray;
    assert.deepStrictEqual([tb.compact.fold, tb.expanded.fold], ["right", "off"]);
    assert.ok(!Catalog.validStyle("tray", "compact"));
    assert.ok(!Catalog.validStyle("battery", "upright"));
    assert.ok(!Catalog.validStyle("battery", "default"));
    const d = JSON.parse(JSON.stringify(factory.island));
    d.island.widgets = d.island.widgets.map(w => w.id === "battery" ? Object.assign({}, w, { compact: "default", expanded: "defaultCard" }) : w);
    const db = M.merge(d, factory.island).island.widgets.find(w => w.id === "battery");
    assert.deepStrictEqual([db.compact, db.expanded], ["shapes", "shapesCard"]);
});

test("island anchors: per mode, gaps and section cards filled and type-checked", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    delete island.island.anchors;
    const a = M.merge(island, factory.island).island.anchors;
    const mode = { anchorCenter: false, between: 8, center: { card: false }, gap: 8, left: { card: false }, right: { card: false } };
    assert.deepStrictEqual(a, { compact: mode, expanded: mode });
    island.island.anchors = { compact: { gap: "wide", right: { card: true } } };
    const b = M.merge(island, factory.island).island.anchors;
    assert.strictEqual(b.compact.gap, 8);
    assert.strictEqual(b.compact.right.card, true);
    assert.strictEqual(b.expanded.right.card, false);
});

test("island anchors: the flat ones and anchorCenter go to both modes", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.anchors = { gap: 4, between: 20, left: { card: true } };
    island.island.anchorCenter = true;
    const m = M.merge(island, factory.island).island;
    assert.ok(!("anchorCenter" in m));
    for (const mode of ["compact", "expanded"]) {
        assert.strictEqual(m.anchors[mode].anchorCenter, true);
        assert.strictEqual(m.anchors[mode].gap, 4);
        assert.strictEqual(m.anchors[mode].between, 20);
        assert.strictEqual(m.anchors[mode].left.card, true);
        assert.strictEqual(m.anchors[mode].right.card, false);
    }
});

test("workspaces: Shapes became Two tones; the label and windows validate; the dock's Shapes went", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.workspaces = { label: "klingon", focus: "shape", windows: { compact: "apps", expanded: "shapes", max: 2 } };
    island.island.widgets = island.island.widgets.map(w => w.id === "workspaces" ? Object.assign({}, w, { compact: "shapes", expanded: "shapesCard" }) : w.id === "dock" ? Object.assign({}, w, { compact: "shapesCard", expanded: "shapes" }) : w);
    const m = M.merge(island, factory.island).island;
    const ws = m.widgets.find(w => w.id === "workspaces");
    assert.deepStrictEqual([ws.compact, ws.expanded], ["tones", "tonesCard"]);
    const dock = m.widgets.find(w => w.id === "dock");
    assert.deepStrictEqual([dock.compact, dock.expanded], ["iconsCard", "icons"]);
    assert.strictEqual(m.workspaces.label, "number");
    assert.strictEqual(m.workspaces.focus, "shape");
    assert.deepStrictEqual(m.workspaces.windows, { compact: "apps", expanded: "icons", max: 2 });
});

test("dashboard: the global Random shapes off goes into every entry's options, then goes", () => {
    const dash = JSON.parse(JSON.stringify(factory.dashboard));
    dash.dashboard.randomShapes = false;
    dash.dashboard.widgets = dash.dashboard.widgets.map(w => w.id === "calendar" ? Object.assign({}, w, { options: { randomShapes: true } }) : w);
    const m = M.merge(dash, factory.dashboard).dashboard;
    assert.ok(!("randomShapes" in m));
    for (const w of m.widgets.filter(w => !w.off))
        assert.strictEqual(w.options.randomShapes, w.id === "calendar", w.id);
    // on (or never set): nothing written
    const on = JSON.parse(JSON.stringify(factory.dashboard));
    on.dashboard.randomShapes = true;
    const m2 = M.merge(on, factory.dashboard).dashboard;
    assert.ok(!("randomShapes" in m2));
    assert.ok(m2.widgets.every(w => !("randomShapes" in (w.options ?? {}))));
});

console.log(`${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
