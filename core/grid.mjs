// Pure grid math: no fs, no Qt, no process — safe to import from QML (as an
// ECMAScript module) and from node (unit tests) without any adapter.

export function monitorFactor(config, monitorName) {
    return config.monitors?.[monitorName]?.factor ?? 1.0;
}

export function cellSizePx(config, monitorName) {
    const base = config.cell?.base ?? 8;
    return Math.round(base * monitorFactor(config, monitorName));
}

export function cellsToPx(cells, cellPx) {
    return Math.round(cells * cellPx);
}

// Anchor + offset + size (all in cells) -> the pixel geometry a PanelWindow
// needs: which edges to anchor to, the margin from those edges, and the
// window's width/height. This is decision 1c.3 (anchor + offset) written as
// a function instead of as pixels anywhere.
export function islandGeometry(island, cellPx) {
    const offset = island.offset ?? { x: 0, y: 0 };
    const anchor = island.anchor ?? {};
    return {
        anchors: {
            left: !!anchor.left,
            right: !!anchor.right,
            top: !!anchor.top,
            bottom: !!anchor.bottom,
        },
        margins: {
            left: anchor.left ? cellsToPx(offset.x ?? 0, cellPx) : 0,
            right: anchor.right ? cellsToPx(offset.x ?? 0, cellPx) : 0,
            top: anchor.top ? cellsToPx(offset.y ?? 0, cellPx) : 0,
            bottom: anchor.bottom ? cellsToPx(offset.y ?? 0, cellPx) : 0,
        },
        width: cellsToPx(island.size?.w ?? 1, cellPx),
        height: cellsToPx(island.size?.h ?? 1, cellPx),
    };
}
