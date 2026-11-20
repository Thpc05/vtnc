import { test } from "node:test";
import assert from "node:assert/strict";
import { validateIslandSet } from "../../core/config-shape.mjs";

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
