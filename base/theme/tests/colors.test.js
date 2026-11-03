// Tests for theme/colorRoles.js. Run: node theme/tests/colors.test.js
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const src = fs.readFileSync(path.join(__dirname, "..", "colorRoles.js"), "utf8").replace(/^\.pragma library.*$/m, "");
const R = new Function(src + "\nreturn { TOKENS, resolve, specHex, defaultSpec, describe, clean, roles };")();

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

// a slice of matugen's -j hex output
const data = {
    colors: {
        primary: { light: { color: "#2c6a46" }, dark: { color: "#94d5a8" }, default: { color: "#94d5a8" } },
        on_primary: { light: { color: "#ffffff" }, dark: { color: "#00391e" } },
        surface: { light: { color: "#f6fbf3" }, dark: { color: "#0f1511" } },
        background: { light: { color: "#f6fbf4" }, dark: { color: "#0f1512" } }
    },
    palettes: { primary: { "40": { color: "#006d3f" } } }
};

test("defaults follow the mode", () => {
    assert.strictEqual(R.resolve(data, "dark", "primary"), "#94d5a8");
    assert.strictEqual(R.resolve(data, "light", "primary"), "#2c6a46");
    assert.strictEqual(R.resolve(data, "dark", "overPrimary", ""), "#00391e");
});
test("background defaults to the M3 surface; oled on request", () => {
    assert.strictEqual(R.resolve(data, "dark", "background"), "#0f1511");
    assert.strictEqual(R.resolve(data, "light", "background"), "#f6fbf3");
    assert.strictEqual(R.resolve(data, "dark", "background", "oled"), "#000000");
    assert.strictEqual(R.resolve(data, "light", "background", "oled"), "#ffffff");
});
test("specs: other scheme, tone, hex", () => {
    assert.strictEqual(R.resolve(data, "dark", "primary", "light:primary"), "#2c6a46");
    assert.strictEqual(R.resolve(data, "dark", "primary", "tone:primary:40"), "#006d3f");
    assert.strictEqual(R.resolve(data, "dark", "primary", "#ABCDEF"), "#abcdef");
});
test("bad specs and missing data fall back", () => {
    assert.strictEqual(R.resolve(data, "dark", "primary", "tone:primary:41"), "#94d5a8");
    assert.strictEqual(R.resolve(data, "dark", "primary", "nonsense"), "#94d5a8");
    assert.strictEqual(R.resolve(null, "dark", "primary"), "#99ccfa");
    assert.strictEqual(R.resolve(null, "dark", "primary", "#123456"), "#123456");
});
test("describe and clean", () => {
    assert.strictEqual(R.describe(""), "Auto");
    assert.strictEqual(R.describe("light:on_primary"), "Light · On Primary");
    assert.strictEqual(R.describe("tone:neutral_variant:30"), "Neutral Variant · tone 30");
    assert.deepStrictEqual(R.clean({ primary: "light:primary", nope: "x", surface: 3 }), { primary: "light:primary" });
});
test("every token has a role and a fallback", () => {
    for (const t of R.TOKENS)
        assert.ok(t.role && /^#[0-9a-f]{6}$/.test(t.fallback), t.token);
});

console.log(`${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
