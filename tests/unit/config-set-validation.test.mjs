import { test } from "node:test";
import assert from "node:assert/strict";
import { validateIslandSet, parseIslandSetValue } from "../../core/config-shape.mjs";

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
