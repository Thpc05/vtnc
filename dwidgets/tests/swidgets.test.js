// Tests for dwidgets/sliders/swidgets.js. Run: node dwidgets/tests/swidgets.test.js
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const src = fs.readFileSync(path.join(__dirname, "..", "sliders", "swidgets.js"), "utf8").replace(/^\.pragma library.*$/m, "");
const S = new Function(src + "\nreturn { SWIDGETS, DEFAULT_ITEMS, items, available };")();

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

test("defaults when missing or not a list", () => {
    assert.deepStrictEqual(S.items(undefined), ["volume", "brightness"]);
    assert.deepStrictEqual(S.items({ items: "volume" }), ["volume", "brightness"]);
});
test("unknown ids and duplicates are dropped, the order kept", () => {
    assert.deepStrictEqual(S.items({ items: ["nightLight", "zzz", "mic", "nightLight"] }), ["nightLight", "mic"]);
    assert.deepStrictEqual(S.items({ items: [] }), []);
});
test("available = the rest, catalog order", () => {
    assert.deepStrictEqual(S.available(["brightness"]), ["volume", "mic", "nightLight"]);
});

console.log(passed + " passed, " + failed + " failed");
process.exit(failed ? 1 : 0);
