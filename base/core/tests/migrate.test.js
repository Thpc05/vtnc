// Tests for core/StateMerge.js: the merge against the factory files (fixes, renames, migrations) and
// the helpers Presets uses. Run: node core/tests/migrate.test.js
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const { rootOf, make } = require("./qmljs.js");
const root = rootOf(__dirname);
const { lib } = make(root);

const Catalog = lib("island/widgets/catalog.js", ["WIDGETS", "HIDDEN", "has", "validStyle", "defaultStyle", "baseStyle", "isCard", "cardVariant", "parents"]);
const DCatalog = lib("dashboard/widgets/catalog.js", ["WIDGETS", "MODES", "CARDS", "TRIGGERS", "has", "style", "validStyle", "validSize", "parseSize", "validMode", "expandedSize", "trigger", "expands", "hasEvent", "defaultEntry", "renamed", "baseStyle", "isCard"]);
const ColorRoles = lib("base/theme/colorRoles.js", ["clean", "TOKENS"]);
const M = lib("base/core/StateMerge.js", ["merge", "canonical", "known"], ["Catalog", "DCatalog", "ColorRoles"], [Catalog, DCatalog, ColorRoles]);

const FILES = { island: "config/island", dashboard: "config/dashboard", appearance: "config/appearance", system: "config/system", state: "state" };
const factory = {};
for (const k in FILES)
    factory[k] = JSON.parse(fs.readFileSync(path.join(root, "defaults", FILES[k] + ".json"), "utf8"));

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

test("known drops unknown keys, keeps maps and arrays", () => {
    const d = { a: 1, o: { x: 1 }, map: {}, list: [] };
    const v = { a: 2, stray: 1, o: { x: 2, y: 3 }, map: { k: "v" }, list: [{ z: 1 }] };
    assert.deepStrictEqual(M.known(v, d), { a: 2, o: { x: 2 }, map: { k: "v" }, list: [{ z: 1 }] });
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

test("unknown Iwidget styles fall back; the counts and colours validate", () => {
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
    // no rename is kept any more (R2 C3): an old style id is just unknown
    assert.strictEqual(m.widgets.find(w => w.id === "tray").expanded, factory.island.island.widgets.find(w => w.id === "tray").expanded);
    assert.ok(m.widgets.some(w => w.id === "quick" && w.section === "off"));
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

test("the active window: added off when missing, its options, card variants; visualizer min height", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.widgets = island.island.widgets.filter(w => w.id !== "window");
    delete island.island.window;
    island.island.visualizer = { compact: { bars: 8 } };
    const m = M.merge(island, factory.island).island;
    assert.ok(m.widgets.some(w => w.id === "window" && w.section === "off"));
    assert.strictEqual(m.window.expanded.maxWidth, 280);
    assert.strictEqual(m.window.compact.text, "both");
    assert.strictEqual(m.window.compact.showIcon, true);
    island.island.window = { compact: { text: "middle" }, expanded: { maxWidth: 300 } };
    const w = M.merge(island, factory.island).island.window;
    assert.strictEqual(w.compact.text, "both");
    assert.strictEqual(w.expanded.maxWidth, 300);
    assert.strictEqual(m.visualizer.compact.minHeight, 2);
    assert.ok(Catalog.validStyle("window", "toneCard"));
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

test("battery, volume and tray options: filled when missing, bad values fall back", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    delete island.island.battery;
    delete island.osd.volumeWidget;
    const m = M.merge(island, factory.island);
    assert.strictEqual(m.island.battery.compact.show, "both");
    assert.strictEqual(m.island.battery.color, "primary");
    assert.strictEqual(m.osd.volumeWidget, false);
    island.island.battery = { color: "pink", compact: { show: "icon" }, expanded: { show: "nope" } };
    const b = M.merge(island, factory.island).island.battery;
    assert.deepStrictEqual([b.color, b.compact.show, b.expanded.show], ["primary", "icon", "both"]);
    assert.ok(Catalog.validStyle("battery", "ringCard"));
    assert.ok(Catalog.validStyle("battery", "arcCard"));
    island.island.tray = { compact: { fold: "left" }, expanded: { fold: "up" } };
    const t = M.merge(island, factory.island).island.tray;
    assert.deepStrictEqual([t.compact.fold, t.expanded.fold], ["left", "off"]);
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


test("island widgets: a card's own colour is kept when valid, dropped otherwise", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.widgets = island.island.widgets.map((w, i) => i === 0 ? Object.assign({}, w, { cardColor: "tertiaryContainer" }) : i === 1 ? Object.assign({}, w, { cardColor: "pink" }) : w);
    const m = M.merge(island, factory.island).island.widgets;
    assert.strictEqual(m[0].cardColor, "tertiaryContainer");
    assert.ok(!("cardColor" in m[1]));
    assert.ok(!("cardColor" in m[2]));
    const again = M.merge({ island: Object.assign({}, island.island, { widgets: m }) }, factory.island).island.widgets;
    assert.deepStrictEqual(again, m);
});
test("workspaces: the label and windows validate", () => {
    const island = JSON.parse(JSON.stringify(factory.island));
    island.island.workspaces = { label: "klingon", focus: "shape", windows: { compact: "apps", expanded: "shapes", max: 2 } };
    const m = M.merge(island, factory.island).island;
    assert.strictEqual(m.workspaces.label, "number");
    assert.strictEqual(m.workspaces.focus, "shape");
    assert.deepStrictEqual(m.workspaces.windows, { compact: "apps", expanded: "icons", max: 2 });
});


console.log(`${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
