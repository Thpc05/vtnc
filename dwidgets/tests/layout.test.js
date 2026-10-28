// Tests for dwidgets/layout.js and dwidgets/catalog.js. Run: node dwidgets/tests/layout.test.js
// (the files are QML JS libraries; the loader strips `.pragma library` and evaluates them)
const fs = require("fs");
const path = require("path");
const assert = require("assert");

function load(file, names) {
    const src = fs.readFileSync(path.join(__dirname, "..", file), "utf8").replace(/^\.pragma library.*$/m, "");
    return new Function(src + "\nreturn {" + names.join(",") + "};")();
}

const L = load("layout.js", ["solve", "place", "bounds", "anchor", "overlaps", "drop", "nearestSize", "firstFree"]);
const C = load("catalog.js", ["WIDGETS", "MODES", "TRIGGERS", "has", "style", "validStyle", "validSize", "parseSize", "validMode", "expandedSize", "trigger", "expands", "hasEvent", "defaultEntry"]);

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
const it = (uid, x, y, w, h) => ({ uid, x, y, w, h });
const rect = (res, uid) => {
    const r = res.rects[uid];
    return [r.x, r.y, r.w, r.h];
};
function noOverlaps(res) {
    const keys = Object.keys(res.rects).filter(k => !res.rects[k].hidden);
    for (let i = 0; i < keys.length; i++)
        for (let j = i + 1; j < keys.length; j++)
            assert.ok(!L.overlaps(res.rects[keys[i]], res.rects[keys[j]]), keys[i] + " overlaps " + keys[j]);
}

// the default layout (media 3x4 · quick 3x1 over calendar 3x3 · sliders 1x4)
const dash = [it("media", 0, 0, 3, 4), it("quick", 3, 0, 3, 1), it("calendar", 3, 1, 3, 3), it("sliders", 6, 0, 1, 4)];

// ── base pass ──
test("base: positions kept, bounds", () => {
    const r = L.solve(dash, null, "over");
    assert.deepStrictEqual(rect(r, "quick"), [3, 0, 3, 1]);
    assert.deepStrictEqual(rect(r, "calendar"), [3, 1, 3, 3]);
    assert.strictEqual(r.cols, 7);
    assert.strictEqual(r.rows, 4);
    noOverlaps(r);
});
test("base: a collision pushes the later item down", () => {
    const r = L.solve([it("a", 0, 0, 2, 2), it("b", 1, 1, 2, 2)], null, "over");
    assert.deepStrictEqual(rect(r, "b"), [1, 2, 2, 2]);
});
test("base: same position → list order wins, pushes cascade", () => {
    const r = L.solve([it("a", 0, 0, 2, 1), it("b", 0, 0, 2, 1), it("c", 0, 0, 1, 1)], null, "over");
    assert.deepStrictEqual(rect(r, "a"), [0, 0, 2, 1]);
    assert.deepStrictEqual(rect(r, "b"), [0, 1, 2, 1]);
    assert.deepStrictEqual(rect(r, "c"), [0, 2, 1, 1]);
    noOverlaps(r);
});
test("base: no upward compaction (holes stay)", () => {
    const r = L.solve([it("a", 0, 3, 1, 1)], null, "over");
    assert.deepStrictEqual(rect(r, "a"), [0, 3, 1, 1]);
    assert.strictEqual(r.rows, 4);
});
test("base: bad numbers are sanitized", () => {
    const r = L.solve([it("a", -2, -1, 0, 0)], null, "over");
    assert.deepStrictEqual(rect(r, "a"), [0, 0, 1, 1]);
});
test("unknown expanded uid → base layout", () => {
    const r = L.solve(dash, { uid: "nope", w: 5, h: 5 }, "over");
    assert.deepStrictEqual(rect(r, "quick"), [3, 0, 3, 1]);
});

// ── over ──
test("over: grows down over its neighbour, grid unchanged", () => {
    const r = L.solve(dash, { uid: "quick", w: 3, h: 4 }, "over");
    assert.deepStrictEqual(rect(r, "quick"), [3, 0, 3, 4]);
    assert.strictEqual(r.rects.quick.z, 1);
    assert.deepStrictEqual(rect(r, "calendar"), [3, 1, 3, 3]);
    assert.strictEqual(r.cols, 7);
    assert.strictEqual(r.rows, 4);
});
test("over: bottom-right corner grows left/up", () => {
    const items = [it("a", 0, 0, 2, 2), it("b", 2, 0, 2, 2), it("c", 0, 2, 2, 2), it("d", 2, 2, 2, 2)];
    const r = L.solve(items, { uid: "d", w: 3, h: 3 }, "over");
    assert.deepStrictEqual(rect(r, "d"), [1, 1, 3, 3]);
    assert.strictEqual(r.cols, 4);
    assert.strictEqual(r.rows, 4);
});
test("over: bigger than the grid → grows the grid right/down", () => {
    const items = [it("a", 0, 0, 1, 1), it("b", 1, 0, 1, 1)];
    const r = L.solve(items, { uid: "b", w: 4, h: 3 }, "over");
    assert.deepStrictEqual(rect(r, "b"), [0, 0, 4, 3]);
    assert.strictEqual(r.cols, 4);
    assert.strictEqual(r.rows, 3);
});
test("over: can shrink (keeps its top-left, the grid stays)", () => {
    const r = L.solve(dash, { uid: "media", w: 1, h: 1 }, "over");
    assert.deepStrictEqual(rect(r, "media"), [0, 0, 1, 1]);
    assert.strictEqual(r.cols, 7);
    assert.strictEqual(r.rows, 4);
});
test("push: shrinking pulls nothing up", () => {
    const r = L.solve(dash, { uid: "quick", w: 1, h: 1 }, "push");
    assert.deepStrictEqual(rect(r, "quick"), [3, 0, 1, 1]);
    assert.deepStrictEqual(rect(r, "calendar"), [3, 1, 3, 3]);
    noOverlaps(r);
});
test("over: middle item keeps its top-left when it fits", () => {
    const items = [it("a", 0, 0, 6, 1), it("m", 2, 1, 1, 1), it("z", 0, 5, 6, 1)];
    const r = L.solve(items, { uid: "m", w: 2, h: 2 }, "over");
    assert.deepStrictEqual(rect(r, "m"), [2, 1, 2, 2]);
});

// ── push ──
test("push: pushes the neighbour below down, grid grows downward", () => {
    const r = L.solve(dash, { uid: "quick", w: 3, h: 4 }, "push");
    assert.deepStrictEqual(rect(r, "quick"), [3, 0, 3, 4]);
    assert.deepStrictEqual(rect(r, "calendar"), [3, 4, 3, 3]);
    assert.deepStrictEqual(rect(r, "media"), [0, 0, 3, 4]);
    assert.deepStrictEqual(rect(r, "sliders"), [6, 0, 1, 4]);
    assert.strictEqual(r.rows, 7);
    noOverlaps(r);
});
test("push: growing wider pushes the right neighbour down and cascades", () => {
    const items = [it("a", 0, 0, 1, 1), it("b", 1, 0, 1, 1), it("c", 1, 1, 1, 1)];
    const r = L.solve(items, { uid: "a", w: 2, h: 1 }, "push");
    assert.deepStrictEqual(rect(r, "a"), [0, 0, 2, 1]);
    assert.deepStrictEqual(rect(r, "b"), [1, 1, 1, 1]);
    assert.deepStrictEqual(rect(r, "c"), [1, 2, 1, 1]);
    noOverlaps(r);
});
test("push: at the right edge it grows left to stay inside the columns", () => {
    const items = [it("a", 0, 0, 2, 1), it("b", 2, 0, 1, 1)];
    const r = L.solve(items, { uid: "b", w: 2, h: 2 }, "push");
    assert.deepStrictEqual(rect(r, "b"), [1, 0, 2, 2]);
    assert.deepStrictEqual(rect(r, "a"), [0, 2, 2, 1]);
    assert.strictEqual(r.cols, 3);
    noOverlaps(r);
});
test("push: items above are untouched", () => {
    const items = [it("top", 0, 0, 3, 1), it("a", 0, 1, 1, 1), it("b", 1, 1, 1, 1)];
    const r = L.solve(items, { uid: "a", w: 2, h: 2 }, "push");
    assert.deepStrictEqual(rect(r, "top"), [0, 0, 3, 1]);
    assert.deepStrictEqual(rect(r, "a"), [0, 1, 2, 2]);
    assert.deepStrictEqual(rect(r, "b"), [1, 3, 1, 1]);
    noOverlaps(r);
});

// ── takeover ──
test("takeover: fills the grid, the others are hidden in place", () => {
    const r = L.solve(dash, { uid: "quick", w: 3, h: 4 }, "takeover");
    assert.deepStrictEqual(rect(r, "quick"), [0, 0, 7, 4]);
    assert.strictEqual(r.rects.media.hidden, true);
    assert.deepStrictEqual(rect(r, "media"), [0, 0, 3, 4]);
    assert.strictEqual(r.rects.quick.hidden, false);
    assert.strictEqual(r.cols, 7);
    assert.strictEqual(r.rows, 4);
});
test("takeover: at least its expanded size", () => {
    const r = L.solve([it("a", 0, 0, 1, 1), it("b", 1, 0, 1, 1)], { uid: "a", w: 3, h: 3 }, "takeover");
    assert.deepStrictEqual(rect(r, "a"), [0, 0, 3, 3]);
    assert.strictEqual(r.cols, 3);
});
test("unknown mode falls back to over", () => {
    const r = L.solve(dash, { uid: "quick", w: 3, h: 4 }, "weird");
    assert.deepStrictEqual(rect(r, "calendar"), [3, 1, 3, 3]);
    assert.deepStrictEqual(rect(r, "quick"), [3, 0, 3, 4]);
});
test("solve is pure (input untouched, same output twice)", () => {
    const items = JSON.parse(JSON.stringify(dash));
    const a = L.solve(items, { uid: "quick", w: 3, h: 4 }, "push");
    const b = L.solve(items, { uid: "quick", w: 3, h: 4 }, "push");
    assert.deepStrictEqual(items, dash);
    assert.deepStrictEqual(a, b);
});

// ── editing ──
test("drop: moves the item and pushes the ones it lands on", () => {
    const pos = L.drop(dash, "sliders", 3, 0, 1, 4);
    assert.deepStrictEqual(pos.sliders, { x: 3, y: 0 });
    assert.deepStrictEqual(pos.quick, { x: 3, y: 4 });
    assert.deepStrictEqual(pos.calendar, { x: 3, y: 5 });
    assert.deepStrictEqual(pos.media, { x: 0, y: 0 });
});
test("drop: result is collision-free and stable under solve", () => {
    const pos = L.drop(dash, "media", 2, 1, 3, 4);
    const items = dash.map(i => Object.assign({}, i, pos[i.uid], i.uid === "media" ? { w: 3, h: 4 } : {}));
    const r = L.solve(items, null, "over");
    noOverlaps(r);
    for (const i of items)
        assert.deepStrictEqual([r.rects[i.uid].x, r.rects[i.uid].y], [pos[i.uid].x, pos[i.uid].y], i.uid + " moved by solve");
});
test("drop: a new item (from Off) is added at its spot", () => {
    const pos = L.drop(dash, "new", 7, 0, 2, 2);
    assert.deepStrictEqual(pos.new, { x: 7, y: 0 });
    assert.deepStrictEqual(pos.sliders, { x: 6, y: 0 });
});
test("drop: a resize in place pushes the neighbour below", () => {
    const pos = L.drop(dash, "quick", 3, 0, 3, 2);
    assert.deepStrictEqual(pos.quick, { x: 3, y: 0 });
    assert.deepStrictEqual(pos.calendar, { x: 3, y: 2 });
});
test("nearestSize: closest, ties to the smaller area", () => {
    assert.strictEqual(L.nearestSize(["1x1", "2x1", "2x2", "3x2"], 2, 2), "2x2");
    assert.strictEqual(L.nearestSize(["1x1", "2x1", "2x2", "3x2"], 5, 5), "3x2");
    assert.strictEqual(L.nearestSize(["1x1", "2x2"], 1.5, 1.5), "1x1");
    assert.strictEqual(L.nearestSize(["3x1"], 9, 9), "3x1");
    assert.strictEqual(L.nearestSize([], 1, 1), null);
});
test("firstFree: first hole row by row, else below", () => {
    assert.deepStrictEqual(L.firstFree(dash, 1, 1, 7), { x: 0, y: 4 });
    assert.deepStrictEqual(L.firstFree(dash, 1, 1, 8), { x: 7, y: 0 });
    assert.deepStrictEqual(L.firstFree([], 2, 2, 0), { x: 0, y: 0 });
    assert.deepStrictEqual(L.firstFree([it("a", 0, 0, 1, 1)], 1, 1, 3), { x: 1, y: 0 });
});

// ── catalog ──
test("catalog: every Dwidget is well formed", () => {
    for (const id in C.WIDGETS) {
        const w = C.WIDGETS[id];
        assert.ok(w.title && w.icon, id + " title/icon");
        assert.ok(w.styles.length > 0, id + " styles");
        w.styles.forEach(s => {
            assert.ok(s.sizes.length > 0, id + "." + s.id + " sizes");
            s.sizes.forEach(z => assert.ok(C.parseSize(z), id + "." + s.id + " size " + z));
        });
        assert.ok(C.validSize(id, w.defaults.idle.style, w.defaults.idle.size), id + " default idle");
        if (w.expand) {
            assert.ok(C.parseSize(w.expand.size), id + " expand size");
            assert.ok(C.TRIGGERS.indexOf(w.expand.trigger) >= 0 && (w.expand.trigger !== "none") !== !!w.expand.panelOnly, id + " expand trigger");
        }
    }
});
test("catalog: helpers", () => {
    assert.deepStrictEqual(C.parseSize("3x2"), { w: 3, h: 2 });
    assert.strictEqual(C.parseSize("0x2"), null);
    assert.strictEqual(C.parseSize("big"), null);
    assert.ok(C.validSize("placeholder", "box", "3x2"));
    assert.ok(!C.validSize("placeholder", "box", "9x9"));
    assert.deepStrictEqual(C.validMode("quick", { style: "shapes", size: "4x4" }, { style: "shapes", size: "3x1" }), { style: "shapes", size: "4x4" });
    assert.deepStrictEqual(C.validMode("placeholder", { style: "tall", size: "4x3" }, { style: "box", size: "2x2" }), { style: "tall", size: "1x2" });
    assert.deepStrictEqual(C.validMode("quick", { style: "zzz" }, { style: "shapes", size: "4x2" }), { style: "shapes", size: "4x2" });
    // a size the style doesn't offer → the fallback's, else the style's first size
    assert.deepStrictEqual(C.validMode("quick", { style: "shapes", size: "9x1" }, { style: "shapes", size: "4x2" }), { style: "shapes", size: "4x2" });
    assert.deepStrictEqual(C.validMode("quick", { style: "shapes", size: "9x1" }, { style: "shapes", size: "9x9" }), { style: "shapes", size: "4x1" });
    assert.deepStrictEqual(C.validMode("quick", null, { style: "shapes", size: "4x2" }), { style: "shapes", size: "4x2" });
    // expanding is the catalog's: only the Dwidgets that need it (Wi-Fi / Bluetooth, the debug box)
    assert.strictEqual(C.trigger({ id: "wifi" }), "doubleclick");
    assert.strictEqual(C.trigger({ id: "media", expandOn: "click" }), "none");
    // an expanding Dwidget's entry may pick its event
    assert.strictEqual(C.trigger({ id: "wifi", expandOn: "hover" }), "hover");
    assert.strictEqual(C.trigger({ id: "wifi", expandOn: "none" }), "none");
    assert.ok(C.expands("bluetooth") && !C.expands("media"));
    // Quick configs expands only for the Mixer's panel: no event of its own
    assert.ok(C.expands("quick") && !C.hasEvent("quick") && C.hasEvent("mixer"));
    assert.strictEqual(C.trigger({ id: "quick", expandOn: "click" }), "none");
    assert.strictEqual(C.trigger({ id: "mixer" }), "click");
    assert.strictEqual(C.expandedSize({ id: "bluetooth", idle: { style: "shapes", size: "2x1" } }), "4x6");
    assert.strictEqual(C.expandedSize({ id: "media", idle: { style: "cover", size: "3x3" } }), "3x3");
    const e = C.defaultEntry("placeholder", "p1", 2, 3);
    assert.deepStrictEqual(e, { uid: "p1", id: "placeholder", idle: { style: "box", size: "2x2" }, x: 2, y: 3, off: false, options: {} });
});

console.log(passed + " passed, " + failed + " failed");
process.exit(failed ? 1 : 0);
