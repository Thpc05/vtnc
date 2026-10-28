// Tests for core/launch.js (launch targets). Run: node core/tests/launch.test.js
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const src = fs.readFileSync(path.join(__dirname, "..", "launch.js"), "utf8").replace(/^\.pragma.*$/m, "");
const L = new Function(src + "\nreturn { VTNC_APPS, parse, valid, format };")();

let passed = 0, failed = 0;
function test(name, fn) {
    try {
        fn();
        passed++;
    } catch (e) {
        failed++;
        console.log("FAIL " + name + "\n  " + e.message);
    }
}

test("vtnc apps and settings pages", () => {
    assert.deepStrictEqual(L.parse("vtnc:settings"), { kind: "vtnc", id: "settings", arg: "" });
    assert.deepStrictEqual(L.parse("vtnc:settings/appearance"), { kind: "vtnc", id: "settings", arg: "appearance" });
    assert.deepStrictEqual(L.parse("vtnc:launcher"), { kind: "vtnc", id: "launcher", arg: "" });
    assert.strictEqual(L.parse("vtnc:nope"), null);
    // only the settings take a page
    assert.strictEqual(L.parse("vtnc:tools/x"), null);
});

test("desktop apps", () => {
    assert.deepStrictEqual(L.parse("desktop:firefox"), { kind: "desktop", id: "firefox", arg: "" });
    assert.deepStrictEqual(L.parse("desktop:org.gnome.Nautilus"), { kind: "desktop", id: "org.gnome.Nautilus", arg: "" });
});

test("invalid targets", () => {
    for (const t of ["", "firefox", "cmd:ls", "desktop:", "vtnc:", null, 3, {}])
        assert.strictEqual(L.valid(t), false, String(t));
});

test("format round-trips", () => {
    assert.strictEqual(L.format("vtnc", "settings", "island"), "vtnc:settings/island");
    assert.strictEqual(L.format("desktop", "kitty", ""), "desktop:kitty");
    assert.ok(L.valid(L.format("vtnc", "dashboard")));
});

console.log(`${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
