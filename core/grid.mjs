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

// Which single edge (if any) a layer-shell surface anchored this way can
// reserve space on. Measured empirically against Hyprland 0.57 in the
// nested compositor (0.504), with WlrLayershell.exclusionMode forced to
// Normal and a fixed exclusiveZone, rather than taken from the protocol
// spec: a lone edge reserves; that edge plus both of its perpendicular
// edges (a full-width/height strip, e.g. top+left+right) also reserves,
// on the lone edge only; anything else — a bare corner (e.g. top+left), or
// both opposite edges with no perpendicular pair (e.g. top+bottom) — is
// ambiguous to Hyprland and reserves nothing, confirming the risk recorded
// in the graph (a corner-anchored island that doesn't span its edge was
// drawn over, not pushed into). Returns null when no single edge applies.
export function primaryExclusiveEdge(anchor) {
    const top = !!anchor.top;
    const bottom = !!anchor.bottom;
    const left = !!anchor.left;
    const right = !!anchor.right;

    const verticalSingle = top !== bottom;
    const horizontalSingle = left !== right;
    const horizontalPairedOrNeither = left === right;
    const verticalPairedOrNeither = top === bottom;

    if (verticalSingle && horizontalPairedOrNeither) return top ? "top" : "bottom";
    if (horizontalSingle && verticalPairedOrNeither) return left ? "left" : "right";
    return null;
}

// The exclusive-zone reservation for an island (decision 1d.5/2d.3/2d.4):
// the island's own rectangle, on its anchored edge only, plus its optional
// gap — in pixels, ready for WlrLayershell.exclusiveZone. Frozen to the
// island's configured size, never the page actually on screen (decision
// 2d.4), and zero whenever there's no idle page or no single anchored edge
// to reserve on (decision 2d.4/1d.5): island without an idle page, or
// without one coverable edge, never pushes anything.
export function exclusiveZone(island, cellPx) {
    const hasIdlePage = !!island.page;
    const edge = hasIdlePage ? primaryExclusiveEdge(island.anchor ?? {}) : null;
    if (!edge) return { edge: null, px: 0 };

    const gapPx = cellsToPx(island.gap ?? 0, cellPx);
    const sizeCells = edge === "top" || edge === "bottom" ? (island.size?.h ?? 1) : (island.size?.w ?? 1);
    return { edge, px: cellsToPx(sizeCells, cellPx) + gapPx };
}
