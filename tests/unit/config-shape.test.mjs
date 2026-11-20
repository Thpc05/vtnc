import { test } from "node:test";
import assert from "node:assert/strict";
import { defaultConfig, findIsland, findPage } from "../../core/config-shape.mjs";

test("a fresh config has no islands or pages", () => {
    const config = defaultConfig();
    assert.deepEqual(config.islands, []);
    assert.deepEqual(config.pages, {});
});

test("findIsland looks up by name, findPage by key", () => {
    const config = {
        islands: [{ name: "bar", page: "clock" }],
        pages: { clock: { grid: { cols: 1, rows: 1 } } },
    };
    assert.equal(findIsland(config, "bar").page, "clock");
    assert.equal(findIsland(config, "missing"), undefined);
    assert.equal(findPage(config, "clock").grid.cols, 1);
    assert.equal(findPage(config, "missing"), undefined);
});
