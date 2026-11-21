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

// Which of an island's anchored edges its hover-reveal trigger lives
// nearest to, and how far (in cells) the island itself rests from it
// (0.505, decision 11.2e: the trigger area is always at the nearest
// monitor border, even for an island that lives far from it; decision
// 11.2b: that same distance, against the global trigger distance, is what
// picks the animation). An island anchored to more than one edge (a
// corner) uses whichever of its anchored edges it actually sits closest
// to. One anchored to no edge at all — not exercised by any island in
// this catalog yet — has no border to call its own: reads as infinitely
// far, so it always shrinks and is never revealed by hover, only by call.
export function nearestBorder(island) {
    const anchor = island.anchor ?? {};
    const offset = island.offset ?? { x: 0, y: 0 };
    const anchoredEdges = ["top", "bottom", "left", "right"].filter((edge) => anchor[edge]);
    if (anchoredEdges.length === 0) return { edge: null, offsetCells: Infinity };

    let best = anchoredEdges[0];
    let bestOffset = Infinity;
    for (const edge of anchoredEdges) {
        const offsetCells = Math.abs(edge === "top" || edge === "bottom" ? (offset.y ?? 0) : (offset.x ?? 0));
        if (offsetCells < bestOffset) {
            bestOffset = offsetCells;
            best = edge;
        }
    }
    return { edge: best, offsetCells: bestOffset };
}

// Slide for an island resting close to its border, shrink for one living
// far from it (decision 11.2b) — "close" meaning strictly nearer than the
// global trigger distance. At the two ends of that range this naturally
// settles on one animation for everything, with no special case needed:
// distance 0 means no island is ever closer than it (all shrink); a
// distance past any real offset means every island is closer than it (all
// slide).
export function autohideAnimation(island, triggerDistanceCells) {
    return nearestBorder(island).offsetCells < triggerDistanceCells ? "slide" : "shrink";
}

// Whether the current Hyprland state says this island's autohide_mode
// (decision 11.2c) wants it hidden right now. hyprlandState is already-read
// plain data ({ hasWindows, hasFullscreen }) — reading it from the
// Quickshell.Hyprland module's live objects is QML's job, not this file's,
// so this stays pure and testable without a compositor.
export function modeSaysHide(mode, hyprlandState) {
    if (mode === "window") return !!hyprlandState?.hasWindows;
    if (mode === "fullscreen") return !!hyprlandState?.hasFullscreen;
    return true; // "always"
}

// The island's own on-screen rectangle in the monitor's absolute pixel
// space (Hyprland's global compositor coordinates, the same space
// hyprctl cursorpos reports in) — needed so a revealed island stays
// revealed while the mouse is over its own body, not just the border
// strip (0.505; not something the graph pins down, an implementation
// choice to avoid the island flickering shut the moment the mouse leaves
// the trigger strip to reach its own content).
export function islandAbsoluteRect(island, cellPx, monitor) {
    const geometry = islandGeometry(island, cellPx);
    const x = geometry.anchors.left
        ? monitor.x + geometry.margins.left
        : geometry.anchors.right
            ? monitor.x + monitor.width - geometry.margins.right - geometry.width
            : monitor.x + (monitor.width - geometry.width) / 2;
    const y = geometry.anchors.top
        ? monitor.y + geometry.margins.top
        : geometry.anchors.bottom
            ? monitor.y + monitor.height - geometry.margins.bottom - geometry.height
            : monitor.y + (monitor.height - geometry.height) / 2;
    return { x, y, width: geometry.width, height: geometry.height };
}

// Is this point within `bandPx` of the monitor's edge named `edge`? Used
// to reveal a hidden island by hover (decision 11.2d) without any extra
// surface to detect it: wlr-layer-shell has no "hover but let the click
// through" region, an input region that sees pointer-enter sees the click
// under it too, so the trigger has to be read from Hyprland's own cursor
// position instead (core/HoverCursor.qml polls hyprctl cursorpos for it).
export function cursorNearBorder(cursor, edge, monitor, bandPx) {
    if (!edge) return false;
    const withinX = cursor.x >= monitor.x && cursor.x < monitor.x + monitor.width;
    const withinY = cursor.y >= monitor.y && cursor.y < monitor.y + monitor.height;
    switch (edge) {
        case "top": return withinX && cursor.y >= monitor.y && cursor.y < monitor.y + bandPx;
        case "bottom": return withinX && cursor.y <= monitor.y + monitor.height && cursor.y > monitor.y + monitor.height - bandPx;
        case "left": return withinY && cursor.x >= monitor.x && cursor.x < monitor.x + bandPx;
        case "right": return withinY && cursor.x <= monitor.x + monitor.width && cursor.x > monitor.x + monitor.width - bandPx;
        default: return false;
    }
}

export function cursorOverRect(cursor, rect) {
    return cursor.x >= rect.x && cursor.x < rect.x + rect.width && cursor.y >= rect.y && cursor.y < rect.y + rect.height;
}
