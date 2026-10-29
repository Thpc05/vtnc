// Tests for apps/settings/tree.js. Run: node apps/settings/tests/tree.test.js
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const src = fs.readFileSync(path.join(__dirname, "..", "tree.js"), "utf8").replace(/^\.pragma library.*$/m, "");
const T = new Function(src + "\nreturn { TREE, leaves, resolve, find };")();

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

test("leaves: sub-pages as parent/child, leaf pages bare, unique", () => {
    const paths = T.leaves().map(l => l.path);
    assert.ok(paths.includes("island/autohide"));
    assert.ok(paths.includes("presets"));
    assert.ok(!paths.includes("island"));
    assert.strictEqual(new Set(paths).size, paths.length);
});
test("resolve: a parent to its first sub-page, old paths moved, unknown to the first page", () => {
    assert.strictEqual(T.resolve("island"), "island/general");
    assert.strictEqual(T.resolve("island/widgets"), "island/layout");
    assert.strictEqual(T.resolve("island/osd"), "appearance/popups");
    assert.strictEqual(T.resolve("nope"), T.leaves()[0].path);
});
test("find: path, sub-page title, top-level id or title; case and spaces ignored", () => {
    assert.strictEqual(T.find("island/autohide"), "island/autohide");
    assert.strictEqual(T.find("Auto Hide"), "island/autohide");
    assert.strictEqual(T.find("Dino run"), "apps/dino");
    assert.strictEqual(T.find("dashboard"), "dashboard/general");
    assert.strictEqual(T.find("System"), "system");
    assert.strictEqual(T.find("nothing"), "");
});
test("every page resolves to itself", () => {
    for (const l of T.leaves())
        assert.strictEqual(T.resolve(l.path), l.path, l.path);
});

console.log(`${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
