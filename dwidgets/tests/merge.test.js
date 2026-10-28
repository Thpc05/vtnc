// Tests for the dashboard part of core/StateMerge.js. Run: node dwidgets/tests/merge.test.js
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const root = path.join(__dirname, "..", "..");
const strip = f => fs.readFileSync(path.join(root, f), "utf8").replace(/^\.(pragma|import).*$/mg, "");
const lib = (f, names, args = [], vals = []) => new Function(...args, strip(f) + "\nreturn {" + names.join(",") + "};")(...vals);

const Catalog = lib("iwidgets/catalog.js", ["WIDGETS", "HIDDEN", "has", "validStyle", "defaultStyle"]);
const DCatalog = lib("dwidgets/catalog.js", ["WIDGETS", "MODES", "CARDS", "TRIGGERS", "has", "style", "validStyle", "validSize", "parseSize", "validMode", "expandedSize", "trigger", "expands", "hasEvent", "defaultEntry", "renamed", "baseStyle", "isCard"]);
const ColorRoles = lib("theme/colorRoles.js", ["clean", "TOKENS"]);
const M = lib("core/StateMerge.js", ["merge", "canonical", "mergeDashboard"], ["Catalog", "DCatalog", "ColorRoles"], [Catalog, DCatalog, ColorRoles]);
// every file's factory defaults in one object (core/STATE.md)
const defaults = Object.assign({}, ...["config/island", "config/dashboard", "config/appearance", "config/system", "state"].map(f => JSON.parse(fs.readFileSync(path.join(root, "defaults", f + ".json"), "utf8"))));

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
const merged = user => M.mergeDashboard(user, defaults.dashboard.widgets);

test("defaults merge to themselves", () => {
    const m = M.merge(defaults, defaults);
    assert.strictEqual(M.canonical(m), M.canonical(defaults));
});
test("not an array → the defaults", () => {
    assert.deepStrictEqual(merged(null), defaults.dashboard.widgets);
});
test("missing catalog Dwidgets are appended off; debug ones aren't", () => {
    const m = merged([{ uid: "quick", id: "quick", idle: { style: "expressive", size: "3x1" }, x: 0, y: 0 }]);
    const ids = m.map(e => e.id);
    assert.deepStrictEqual(ids.slice().sort(), ["bluetooth", "calendar", "clipboard", "clock", "colorScheme", "dino", "image", "media", "mixer", "notes", "notifications", "powerProfile", "quick", "sliders", "visualizer", "wallpaper", "wifi"]);
    assert.ok(m.filter(e => e.id !== "quick").every(e => e.off === true));
    assert.strictEqual(m.find(e => e.id === "quick").off, false);
    assert.ok(!ids.includes("placeholder"));
});
test("a debug entry the user placed is kept", () => {
    const m = merged([{ uid: "p", id: "placeholder" }]);
    assert.ok(m.some(e => e.uid === "p" && e.id === "placeholder"));
});
test("duplicates by uid are dropped, copies with their own uid kept", () => {
    const m = merged([{ uid: "media", id: "media" }, { uid: "media", id: "media" }, { uid: "media-2", id: "media" }]);
    assert.strictEqual(m.filter(e => e.id === "media").length, 2);
});
test("only the original may be off: an off copy goes, or stands in for a missing original", () => {
    const m = merged([{ uid: "p1", id: "placeholder", off: true }, { uid: "p2", id: "placeholder", off: true }, { uid: "p3", id: "placeholder" }]);
    assert.deepStrictEqual(m.filter(e => e.id === "placeholder").map(e => [e.uid, e.off]), [["placeholder", true], ["p3", false]]);
    const n = merged([{ uid: "media", id: "media" }, { uid: "media-2", id: "media", off: true }]);
    assert.deepStrictEqual(n.filter(e => e.id === "media").map(e => e.uid), ["media"]);
    // only copies left: the original comes back, off
    const o = merged([{ uid: "sliders-2", id: "sliders" }]);
    assert.deepStrictEqual(o.filter(e => e.id === "sliders").map(e => [e.uid, e.off]), [["sliders-2", false], ["sliders", true]]);
});
test("bad fields fall back", () => {
    const [e] = merged([{ id: "media", idle: { style: "zzz", size: "9x9" }, expanded: 5, x: -3, y: 2.7, expandOn: "wat", off: "yes", options: [] }]);
    assert.deepStrictEqual(e, { uid: "media", id: "media", idle: { style: "shapes", size: "4x2" }, x: 0, y: 2, off: false, options: {} });
});
test("migrates the old one-style shape; expanded looks and events are dropped", () => {
    const m = merged([
        { uid: "q", id: "quick", style: "row", size: "9x1", x: 1, y: 0, expandOn: "" },
        { uid: "p", id: "placeholder", style: "tall", size: "1x3", expandOn: "hover" },
        { uid: "w", id: "wifi", idle: { style: "expressive", size: "2x1" }, expanded: { style: "expressive", size: "3x4" }, expandOn: "click" }
    ]);
    const q = m.find(e => e.uid === "q");
    assert.deepStrictEqual(q.idle, { style: "shapes", size: "4x1" });
    assert.ok(!("style" in q) && !("size" in q) && !("expanded" in q) && !("expandOn" in q));
    assert.deepStrictEqual(m.find(e => e.uid === "p").idle, { style: "tall", size: "1x3" });
    assert.ok(!("expanded" in m.find(e => e.uid === "w")));
});
test("expandOn is kept only for a Dwidget that expands", () => {
    const m = merged([{ uid: "w", id: "wifi", expandOn: "hover" }, { uid: "m", id: "media", expandOn: "click" }, { uid: "b", id: "bluetooth", expandOn: "wat" }]);
    assert.strictEqual(m.find(e => e.uid === "w").expandOn, "hover");
    assert.ok(!("expandOn" in m.find(e => e.uid === "m")));
    assert.ok(!("expandOn" in m.find(e => e.uid === "b")));
});
test("quick: old arrangement styles take the default look; options.layout goes", () => {
    const [q] = merged([{ uid: "q", id: "quick", idle: { style: "tiles", size: "4x2" }, options: { items: ["dnd"], layout: "list" } }]);
    assert.deepStrictEqual(q.idle, { style: "shapes", size: "4x2" });
    assert.deepStrictEqual(q.options, { items: ["dnd"] });
    const [again] = merged([q]);
    assert.deepStrictEqual(again, q);
});
test("quick: a dropped style (tonal, sumi, caelestia, oneui…) becomes the default look (shapes, no card), the size kept", () => {
    const [q] = merged([{ uid: "q", id: "quick", idle: { style: "tonal", size: "4x2" } }]);
    assert.deepStrictEqual(q.idle, { style: "shapes", size: "4x2" });
});
test("merging twice is stable", () => {
    const once = merged([{ uid: "c", id: "calendar", x: 1, y: 1 }]);
    assert.strictEqual(M.canonical(merged(once)), M.canonical(once));
});

// (2026-10-27: 3x3 and up are the toggles' panel sizes, so an old panel look keeps its size, the panel)
test("toggles: panel styles and the old mixer looks become the toggle (now the default look, shapes)", () => {
    const m = merged([{ uid: "a", id: "mixer", idle: { style: "expressive", size: "3x4" } }, { uid: "b", id: "mixer", idle: { style: "expressiveNoCard", size: "4x3" } }, { uid: "c", id: "wifi", idle: { style: "expressivePanel", size: "3x4" } }, { uid: "d", id: "bluetooth", idle: { style: "expressive", size: "1x2" } }, { uid: "e", id: "wifi", idle: { style: "expressive", size: "5x1" } }]);
    assert.deepStrictEqual(m.find(e => e.uid === "a").idle, { style: "shapes", size: "3x4" });
    assert.deepStrictEqual(m.find(e => e.uid === "b").idle, { style: "shapes", size: "4x3" });
    assert.deepStrictEqual(m.find(e => e.uid === "c").idle, { style: "shapes", size: "3x4" });
    assert.deepStrictEqual(m.find(e => e.uid === "e").idle, { style: "shapes", size: "2x1" });
    assert.deepStrictEqual(m.find(e => e.uid === "d").idle, { style: "shapes", size: "1x2" });
});

test("the Iwidget family: card variants; old no-card ids renamed", () => {
    const m = merged([
        { uid: "a", id: "quick", idle: { style: "tonesNoCard", size: "4x1" } },
        { uid: "b", id: "quick", idle: { style: "toneCard", size: "4x2" } },
        { uid: "c", id: "wifi", idle: { style: "tonesCard", size: "1x1" } }
    ]);
    assert.deepStrictEqual(m.find(e => e.uid === "a").idle, { style: "tones", size: "4x1" });
    assert.deepStrictEqual(m.find(e => e.uid === "b").idle, { style: "toneCard", size: "4x2" });
    assert.deepStrictEqual(m.find(e => e.uid === "c").idle, { style: "tonesCard", size: "1x1" });
    assert.strictEqual(DCatalog.baseStyle("quick", "toneCard"), "tone");
    assert.ok(DCatalog.isCard("wifi", "shapesCard") && !DCatalog.isCard("wifi", "shapes"));
});
test("calendar and media: the old looks map to the family", () => {
    const m = merged([
        { uid: "calendar", id: "calendar", idle: { style: "expressiveNoCard", size: "3x3" } },
        { uid: "calendar-2", id: "calendar", idle: { style: "expressive", size: "4x1" } },
        { uid: "media", id: "media", idle: { style: "discNoCard", size: "4x2" } },
        { uid: "media-2", id: "media", idle: { style: "type", size: "3x4" } },
        { uid: "media-3", id: "media", idle: { style: "android", size: "3x3" } },
        { uid: "media-4", id: "media", idle: { style: "disc", size: "2x2" } }
    ]);
    assert.deepStrictEqual(m.filter(e => e.id === "calendar").map(e => e.idle.style), ["tones", "tonesCard"]);
    assert.deepStrictEqual(m.filter(e => e.id === "media").map(e => e.idle.style), ["disc", "tonesCard", "shapesCard", "disc"]);
    assert.strictEqual(DCatalog.baseStyle("media", "discCard"), "disc");
});
test("sliders: the old looks map to the family", () => {
    const m = merged([
        { uid: "sliders", id: "sliders", idle: { style: "inset", size: "2x3" } },
        { uid: "sliders-2", id: "sliders", idle: { style: "wavyNoCard", size: "1x4" } },
        { uid: "sliders-3", id: "sliders", idle: { style: "wavy", size: "4x1" } }
    ]);
    assert.deepStrictEqual(m.filter(e => e.id === "sliders").map(e => e.idle.style), ["shapes", "tone", "toneCard"]);
});

console.log(passed + " passed, " + failed + " failed");
process.exit(failed ? 1 : 0);
