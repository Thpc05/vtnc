// Tests for dwidgets/quick/qwidgets.js. Run: node dwidgets/tests/qwidgets.test.js
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const src = fs.readFileSync(path.join(__dirname, "..", "quick", "qwidgets.js"), "utf8").replace(/^\.pragma library.*$/m, "");
const Q = new Function(src + "\nreturn { QWIDGETS, GROUPS, MAX_ITEMS, DEFAULT_ITEMS, has, idOf, raw, items, available, arrange };")();

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

const ids = list => list.map(i => i.id);

test("defaults when missing or not a list", () => {
    assert.deepStrictEqual(ids(Q.items(undefined)), Q.DEFAULT_ITEMS);
    assert.deepStrictEqual(ids(Q.items({})), Q.DEFAULT_ITEMS);
    assert.deepStrictEqual(ids(Q.items({ items: "wifi" })), Q.DEFAULT_ITEMS);
});
test("keeps order and repeats, drops unknown", () => {
    const list = Q.items({ items: ["dnd", "nope", "wifi", "dnd", 3, { id: "zzz" }] });
    assert.deepStrictEqual(ids(list), ["dnd", "wifi", "dnd"]);
    assert.deepStrictEqual(list.map(i => i.key), ["dnd#1", "wifi#1", "dnd#2"]);
    assert.strictEqual(Q.idOf("dnd#2"), "dnd");
});
test("instances: an object carries its config", () => {
    const list = Q.items({ items: ["app", { id: "app", target: "desktop:kitty" }, "caffeine"] });
    assert.deepStrictEqual(list[0], { key: "app#1", id: "app", config: {} });
    assert.deepStrictEqual(list[1], { key: "app#2", id: "app", config: { target: "desktop:kitty" } });
    // raw keeps the stored shape (the editor writes it back)
    assert.deepStrictEqual(Q.raw({ items: ["x", { id: "app", target: "vtnc:settings" }] }), [{ id: "app", target: "vtnc:settings" }]);
});
test("at most MAX_ITEMS; nothing more to add then", () => {
    const many = Array(40).fill("caffeine");
    assert.strictEqual(Q.items({ items: many }).length, Q.MAX_ITEMS);
    assert.deepStrictEqual(Q.available(Q.items({ items: many })), []);
});
test("an array-like list (Qt's sequence from a model) counts as a list", () => {
    const seq = { length: 2, 0: "caffeine", 1: "wifi" };
    assert.deepStrictEqual(ids(Q.items({ items: seq })), ["caffeine", "wifi"]);
});
test("an empty list stays empty", () => {
    assert.deepStrictEqual(Q.items({ items: [] }), []);
});
test("available = the whole catalog (they repeat), catalog order; the island leaves the Mixer out", () => {
    const a = Q.available(Q.items({ items: ["wifi", "dnd"] }));
    assert.ok(a.includes("wifi") && a.includes("dnd"));
    assert.strictEqual(a.length, Object.keys(Q.QWIDGETS).length);
    assert.strictEqual(a[0], "wifi");
    assert.ok(!Q.available([], true).includes("mixer"));
    assert.deepStrictEqual(ids(Q.items({ items: ["mixer", "dnd"] }, true)), ["dnd"]);
});
test("catalog well formed; defaults exist", () => {
    const groups = Q.GROUPS.map(g => g.id);
    for (const id in Q.QWIDGETS) {
        const q = Q.QWIDGETS[id];
        assert.ok(q.title && q.icon && typeof q.panel === "boolean", id);
        assert.ok(["toggle", "action", "app"].includes(q.kind), id);
        assert.ok(groups.includes(q.group), id);
        assert.ok(q.group !== "tools" || q.tool, id);
        assert.ok(q.group !== "session" || q.action, id);
    }
    Q.DEFAULT_ITEMS.forEach(id => assert.ok(Q.has(id), id));
});

test("arrange: pills as few per row as fit; short or narrow → icons", () => {
    assert.deepStrictEqual(Q.arrange(5, 320, 72, 8), { kind: "icons", per: 0 });
    assert.deepStrictEqual(Q.arrange(5, 320, 300, 8), { kind: "pills", per: 1 });
    assert.deepStrictEqual(Q.arrange(5, 320, 150, 8), { kind: "pills", per: 2 });
    assert.strictEqual(Q.arrange(4, 100, 300, 8).kind, "icons");
});

console.log(passed + " passed, " + failed + " failed");
process.exit(failed ? 1 : 0);
