import { test } from "node:test";
import assert from "node:assert/strict";
import { cellSizePx, islandGeometry } from "../../core/grid.mjs";

test("cell size scales with the monitor factor, base stays global", () => {
    const config = { cell: { base: 8 }, monitors: { "HEADLESS-2": { factor: 1.25 } } };
    assert.equal(cellSizePx(config, "HEADLESS-1"), 8); // no factor entry -> 1.0
    assert.equal(cellSizePx(config, "HEADLESS-2"), 10);
});

test("changing the factor changes px size, never the cell layout", () => {
    const island = { anchor: { bottom: true, left: true }, offset: { x: 2, y: 2 }, size: { w: 20, h: 6 } };
    const atFactor1 = islandGeometry(island, 8);
    const atFactor125 = islandGeometry(island, 10);

    assert.deepEqual(atFactor1.anchors, atFactor125.anchors);
    assert.equal(atFactor1.width, 160);
    assert.equal(atFactor1.height, 48);
    assert.equal(atFactor125.width, 200);
    assert.equal(atFactor125.height, 60);
});

test("anchor + offset, never absolute pixels: margin is 0 on edges not anchored", () => {
    const island = { anchor: { top: true }, offset: { x: 5, y: 3 }, size: { w: 1, h: 1 } };
    const geometry = islandGeometry(island, 8);
    assert.equal(geometry.margins.top, 24);
    assert.equal(geometry.margins.left, 0);
    assert.equal(geometry.margins.right, 0);
    assert.equal(geometry.margins.bottom, 0);
});
