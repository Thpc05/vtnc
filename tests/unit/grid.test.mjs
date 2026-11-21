import { test } from "node:test";
import assert from "node:assert/strict";
import {
    cellSizePx, islandGeometry, primaryExclusiveEdge, exclusiveZone,
    nearestBorder, autohideAnimation, modeSaysHide,
    islandAbsoluteRect, cursorNearBorder, cursorOverRect,
} from "../../core/grid.mjs";

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

// Measured against Hyprland 0.57 in the nested test compositor (0.504), not
// deduced from the layer-shell protocol spec, which leaves corner anchors
// undefined. See island/README.md for the full table.
test("primaryExclusiveEdge: a lone edge, or that edge spanning the full width/height, reserves", () => {
    assert.equal(primaryExclusiveEdge({ top: true }), "top");
    assert.equal(primaryExclusiveEdge({ bottom: true }), "bottom");
    assert.equal(primaryExclusiveEdge({ left: true }), "left");
    assert.equal(primaryExclusiveEdge({ right: true }), "right");
    assert.equal(primaryExclusiveEdge({ top: true, left: true, right: true }), "top");
    assert.equal(primaryExclusiveEdge({ left: true, top: true, bottom: true }), "left");
});

test("primaryExclusiveEdge: a bare corner or opposite edges with no perpendicular pair is ambiguous", () => {
    assert.equal(primaryExclusiveEdge({ top: true, left: true }), null);
    assert.equal(primaryExclusiveEdge({ bottom: true, left: true }), null);
    assert.equal(primaryExclusiveEdge({ top: true, bottom: true }), null);
    assert.equal(primaryExclusiveEdge({ left: true, right: true }), null);
    assert.equal(primaryExclusiveEdge({}), null);
});

test("exclusiveZone: the island's own rectangle on the anchored edge, plus the gap, in px", () => {
    const island = { page: "dashboard", anchor: { top: true }, size: { w: 20, h: 6 }, gap: 2 };
    assert.deepEqual(exclusiveZone(island, 8), { edge: "top", px: 48 + 16 }); // 6*8 + 2*8
});

test("exclusiveZone: left/right anchors measure width, not height", () => {
    const island = { page: "dock", anchor: { left: true }, size: { w: 10, h: 30 }, gap: 0 };
    assert.deepEqual(exclusiveZone(island, 8), { edge: "left", px: 80 });
});

test("exclusiveZone: no idle page means no reservation, even if anchored", () => {
    const island = { anchor: { top: true }, size: { w: 10, h: 4 }, gap: 3 };
    assert.deepEqual(exclusiveZone(island, 8), { edge: null, px: 0 });
});

test("exclusiveZone: an ambiguous (corner) anchor means no reservation, even with a gap", () => {
    const island = { page: "dock", anchor: { bottom: true, left: true }, size: { w: 10, h: 4 }, gap: 3 };
    assert.deepEqual(exclusiveZone(island, 8), { edge: null, px: 0 });
});

test("exclusiveZone: a call to a bigger page never changes it — it reads island.size, not the page on screen", () => {
    const island = { page: "idle", anchor: { top: true }, size: { w: 10, h: 4 }, gap: 0 };
    const before = exclusiveZone(island, 8);
    // Simulates what a `call` leaves untouched: island.size itself never
    // changes, so there is nothing here that could observe a bigger page.
    assert.deepEqual(exclusiveZone(island, 8), before);
});

// --- 0.505: autohide ---------------------------------------------------

test("nearestBorder: a single anchored edge, offset in cells along its own axis", () => {
    assert.deepEqual(nearestBorder({ anchor: { top: true }, offset: { x: 0, y: 3 } }), { edge: "top", offsetCells: 3 });
    assert.deepEqual(nearestBorder({ anchor: { left: true }, offset: { x: 5, y: 0 } }), { edge: "left", offsetCells: 5 });
});

test("nearestBorder: a corner picks whichever of its two anchored edges it rests closer to", () => {
    assert.deepEqual(
        nearestBorder({ anchor: { bottom: true, left: true }, offset: { x: 1, y: 4 } }),
        { edge: "left", offsetCells: 1 },
    );
});

test("nearestBorder: no anchor at all means no border and infinite distance", () => {
    assert.deepEqual(nearestBorder({ anchor: {} }), { edge: null, offsetCells: Infinity });
});

test("autohideAnimation: slide when strictly closer than the trigger distance, shrink otherwise", () => {
    const close = { anchor: { top: true }, offset: { x: 0, y: 0 } };
    const far = { anchor: { top: true }, offset: { x: 0, y: 10 } };
    assert.equal(autohideAnimation(close, 2), "slide");
    assert.equal(autohideAnimation(far, 2), "shrink");
});

test("autohideAnimation: the trigger distance's two extremes force one animation for everyone", () => {
    const anyIsland = { anchor: { top: true }, offset: { x: 0, y: 7 } };
    assert.equal(autohideAnimation(anyIsland, 0), "shrink"); // nothing is ever closer than 0
    assert.equal(autohideAnimation(anyIsland, 9999), "slide"); // everything is closer than 9999
});

test("autohideAnimation: an island with no anchored edge always shrinks (infinitely far)", () => {
    assert.equal(autohideAnimation({ anchor: {} }, 9999), "shrink");
});

test("modeSaysHide: always hides unconditionally; window/fullscreen read the given Hyprland state", () => {
    assert.equal(modeSaysHide("always", { hasWindows: false, hasFullscreen: false }), true);
    assert.equal(modeSaysHide("window", { hasWindows: false, hasFullscreen: false }), false);
    assert.equal(modeSaysHide("window", { hasWindows: true, hasFullscreen: false }), true);
    assert.equal(modeSaysHide("fullscreen", { hasWindows: true, hasFullscreen: false }), false);
    assert.equal(modeSaysHide("fullscreen", { hasWindows: true, hasFullscreen: true }), true);
});

test("islandAbsoluteRect: anchored edges place the island against that side of the monitor", () => {
    const island = { anchor: { top: true, left: true }, offset: { x: 1, y: 2 }, size: { w: 10, h: 2 } };
    const monitor = { x: 1920, y: 0, width: 1920, height: 1080 };
    assert.deepEqual(islandAbsoluteRect(island, 8, monitor), { x: 1920 + 8, y: 0 + 16, width: 80, height: 16 });
});

test("cursorNearBorder: within the band on the right edge, outside it, and outside the monitor entirely", () => {
    const monitor = { x: 1920, y: 0, width: 1920, height: 1080 };
    assert.equal(cursorNearBorder({ x: 3835, y: 500 }, "right", monitor, 20), true);
    assert.equal(cursorNearBorder({ x: 3000, y: 500 }, "right", monitor, 20), false);
    assert.equal(cursorNearBorder({ x: 3835, y: 2000 }, "right", monitor, 20), false); // off this monitor
    assert.equal(cursorNearBorder({ x: 3835, y: 500 }, null, monitor, 20), false);
});

test("cursorOverRect: inside vs. outside an island's own rectangle", () => {
    const rect = { x: 100, y: 100, width: 50, height: 20 };
    assert.equal(cursorOverRect({ x: 120, y: 110 }, rect), true);
    assert.equal(cursorOverRect({ x: 200, y: 110 }, rect), false);
});
