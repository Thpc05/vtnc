import { test } from "node:test";
import assert from "node:assert/strict";
import {
    validateIslandSet, parseIslandSetValue,
    validateAutohideGlobalSet, parseAutohideGlobalValue, resolveAutohide,
} from "../../core/config-shape.mjs";

const config = {
    islands: [{ name: "bar", page: "clock" }],
    pages: { clock: { grid: { cols: 1, rows: 1 } } },
};

test("set to an existing page is accepted", () => {
    assert.equal(validateIslandSet("page", "clock", config), null);
});

test("set to a page that doesn't exist is refused", () => {
    const error = validateIslandSet("page", "dashboard", config);
    assert.match(error, /no such page/);
});

test("set on an unknown key is refused", () => {
    const error = validateIslandSet("banana", "7", config);
    assert.match(error, /unknown key/);
});

test("set layer only accepts the four known layers", () => {
    assert.equal(validateIslandSet("layer", "top", config), null);
    assert.match(validateIslandSet("layer", "sideways", config), /invalid layer/);
});

test("set anchor accepts a JSON object of known edges", () => {
    assert.equal(validateIslandSet("anchor", { top: true, left: false }, config), null);
});

test("set anchor refuses an unknown edge or a non-boolean value", () => {
    assert.match(validateIslandSet("anchor", { diagonal: true }, config), /unknown edge/);
    assert.match(validateIslandSet("anchor", { top: "yes" }, config), /must be true or false/);
});

test("set offset/size require a JSON object with numeric fields", () => {
    assert.equal(validateIslandSet("offset", { x: 2, y: 0 }, config), null);
    assert.equal(validateIslandSet("size", { w: 20, h: 6 }, config), null);
    assert.match(validateIslandSet("offset", { x: "2", y: 0 }, config), /must be a number/);
    assert.match(validateIslandSet("size", { w: 0, h: 6 }, config), /greater than zero/);
});

test("set anchor/offset/size reject a value that wasn't valid JSON at all", () => {
    assert.match(validateIslandSet("anchor", undefined, config), /must be a JSON object/);
});

test("parseIslandSetValue decodes JSON only for the object-shaped keys", () => {
    assert.deepEqual(parseIslandSetValue("anchor", '{"top":true}'), { top: true });
    assert.deepEqual(parseIslandSetValue("offset", '{"x":2,"y":0}'), { x: 2, y: 0 });
    assert.equal(parseIslandSetValue("page", "dashboard"), "dashboard");
    assert.equal(parseIslandSetValue("anchor", "not json"), undefined);
});

test("set gap only accepts a whole number, zero or more — never four sides", () => {
    assert.equal(validateIslandSet("gap", 0, config), null);
    assert.equal(validateIslandSet("gap", 3, config), null);
    assert.match(validateIslandSet("gap", -1, config), /invalid gap/);
    assert.match(validateIslandSet("gap", 1.5, config), /invalid gap/);
    assert.match(validateIslandSet("gap", NaN, config), /invalid gap/);
});

test("parseIslandSetValue turns gap's raw string into a number", () => {
    assert.equal(parseIslandSetValue("gap", "2"), 2);
    assert.ok(Number.isNaN(parseIslandSetValue("gap", "two")));
});

// --- 0.505: autohide -----------------------------------------------------

test("parseIslandSetValue turns autohide's raw string into a real boolean, never a truthy string", () => {
    assert.equal(parseIslandSetValue("autohide", "true"), true);
    assert.equal(parseIslandSetValue("autohide", "false"), false);
    assert.equal(parseIslandSetValue("autohide", "banana"), undefined);
});

test("set autohide only accepts a real boolean", () => {
    assert.equal(validateIslandSet("autohide", true, config), null);
    assert.equal(validateIslandSet("autohide", false, config), null);
    assert.match(validateIslandSet("autohide", undefined, config), /must be true or false/);
});

test("set autohideMode only accepts the three known modes", () => {
    assert.equal(validateIslandSet("autohideMode", "always", config), null);
    assert.equal(validateIslandSet("autohideMode", "window", config), null);
    assert.equal(validateIslandSet("autohideMode", "fullscreen", config), null);
    assert.match(validateIslandSet("autohideMode", "sideways", config), /invalid autohideMode/);
});

test("parseAutohideGlobalValue: enabled is a real boolean, distance is a number, mode passes through", () => {
    assert.equal(parseAutohideGlobalValue("enabled", "true"), true);
    assert.equal(parseAutohideGlobalValue("enabled", "false"), false);
    assert.equal(parseAutohideGlobalValue("distance", "3"), 3);
    assert.equal(parseAutohideGlobalValue("mode", "window"), "window");
});

test("validateAutohideGlobalSet: the three global keys, nothing else", () => {
    assert.equal(validateAutohideGlobalSet("enabled", true), null);
    assert.equal(validateAutohideGlobalSet("mode", "fullscreen"), null);
    assert.equal(validateAutohideGlobalSet("distance", 0), null);
    assert.match(validateAutohideGlobalSet("distance", -1), /invalid distance/);
    assert.match(validateAutohideGlobalSet("mode", "sideways"), /invalid mode/);
    assert.match(validateAutohideGlobalSet("gap", 2), /unknown key/);
});

test("resolveAutohide: an island's own autohide/autohideMode override the global default", () => {
    const cfg = { autohide: { enabled: false, mode: "always" } };
    assert.deepEqual(resolveAutohide(cfg, {}), { enabled: false, mode: "always" });
    assert.deepEqual(resolveAutohide(cfg, { autohide: true, autohideMode: "window" }), { enabled: true, mode: "window" });
    // Only the key an island actually set is overridden — the other still
    // falls back to global (decision 11.2c: two independent overrides).
    assert.deepEqual(resolveAutohide(cfg, { autohide: true }), { enabled: true, mode: "always" });
});

test("resolveAutohide: with no global autohide config at all, falls back to off/always", () => {
    assert.deepEqual(resolveAutohide({}, {}), { enabled: false, mode: "always" });
});
