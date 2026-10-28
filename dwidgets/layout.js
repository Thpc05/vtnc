.pragma library

// Dashboard layout engine (see README.md, "Layout engine"). Pure: no QML, no state; the same
// input always gives the same rects, so the final size is known before anything animates.
//
//   solve(items, expanded, mode) → { rects: { uid: { x, y, w, h, z, hidden } }, cols, rows }
//
//   items:    [{ uid, x, y, w, h }] in cells (the entries with their sizes already parsed)
//   expanded: null, or { uid, w, h } = the entry being expanded and its expanded size (bigger or
//             smaller than its idle size)
//   mode:     "over" · "push" · "takeover" (how an expanded entry makes room, below)
//
// Base pass: every item sits at its x/y; an item that collides with one already placed is pushed
// down until it's free. Items are placed top to bottom (y, then x, then list order), so pushes
// cascade. Nothing is compacted upwards: the user's positions are the truth.
//
// Expansion (the rect takes the expanded size; a smaller one keeps its top-left):
//   over      the item grows over its neighbours (z 1). It keeps the corner nearest to the grid's
//             edges with room: it grows right/down when it fits, else left/up; if the grid is too
//             small it grows the grid (right/down)
//   push      it grows right/down from its origin (left when that keeps it inside the columns),
//             and everything it overlaps is pushed down by the base pass: the grid grows downward
//   takeover  it takes the whole grid (at least its expanded size); the others are `hidden`
//             (they keep their rects so they don't move while fading)
//
// Editing (the settings layout editor):
//   drop(items, uid, x, y, w, h)  the positions after dropping `uid` at x/y with size w×h
//   nearestSize(sizes, w, h)      the allowed size closest to w×h (the resize handle)
//   firstFree(items, w, h, cols)  the first free spot for a w×h item

function overlaps(a, b) {
    return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
}

function copy(r) {
    return { x: r.x, y: r.y, w: r.w, h: r.h, z: r.z || 0, hidden: !!r.hidden };
}

// top to bottom, left to right, then list order (Array.sort isn't stable in QML's engine)
function ordered(items) {
    var list = items.map(function (it, i) {
        return { it: it, i: i };
    });
    list.sort(function (a, b) {
        return (a.it.y - b.it.y) || (a.it.x - b.it.x) || (a.i - b.i);
    });
    return list.map(function (e) {
        return e.it;
    });
}

// places `items` around the already placed rects `fixed` (uid → rect), pushing collisions down
function place(items, fixed) {
    var rects = {};
    var placed = [];
    for (var k in fixed) {
        rects[k] = fixed[k];
        placed.push(fixed[k]);
    }
    ordered(items).forEach(function (it) {
        if (rects.hasOwnProperty(it.uid))
            return;
        var r = { x: Math.max(0, it.x | 0), y: Math.max(0, it.y | 0), w: Math.max(1, it.w | 0), h: Math.max(1, it.h | 0), z: 0, hidden: false };
        var moved = true;
        while (moved) {
            moved = false;
            for (var j = 0; j < placed.length; j++) {
                if (overlaps(r, placed[j])) {
                    r.y = placed[j].y + placed[j].h;
                    moved = true;
                }
            }
        }
        rects[it.uid] = r;
        placed.push(r);
    });
    return rects;
}

// size of the grid holding `rects` (hidden ones don't count)
function bounds(rects) {
    var cols = 0, rows = 0;
    for (var k in rects) {
        var r = rects[k];
        if (r.hidden)
            continue;
        cols = Math.max(cols, r.x + r.w);
        rows = Math.max(rows, r.y + r.h);
    }
    return { cols: cols, rows: rows };
}

// start of a span of length `size` that grows from [start, start + len) inside [0, limit):
// keep the start when it fits, else keep the end, else clamp to 0 (and the grid grows)
function anchor(start, len, size, limit) {
    if (start + size <= limit)
        return start;
    var fromEnd = start + len - size;
    if (fromEnd >= 0)
        return fromEnd;
    return 0;
}

function solve(items, expanded, mode) {
    var base = place(items, {});
    var grid = bounds(base);
    var r = expanded ? base[expanded.uid] : undefined;
    if (!r)
        return { rects: base, cols: grid.cols, rows: grid.rows };

    // exactly the expanded size: a second look, it may be smaller than idle
    var w = Math.max(1, expanded.w | 0);
    var h = Math.max(1, expanded.h | 0);
    var rects = {};
    var k;

    if (mode === "takeover") {
        for (k in base) {
            rects[k] = copy(base[k]);
            rects[k].hidden = k !== expanded.uid;
        }
        rects[expanded.uid] = { x: 0, y: 0, w: Math.max(grid.cols, w), h: Math.max(grid.rows, h), z: 1, hidden: false };
    } else if (mode === "push") {
        var grown = { x: anchor(r.x, r.w, w, grid.cols), y: r.y, w: w, h: h, z: 1, hidden: false };
        var fixed = {};
        fixed[expanded.uid] = grown;
        // the others keep their base positions (already collision-free) and get pushed from there
        var rest = items.filter(function (it) {
            return it.uid !== expanded.uid;
        }).map(function (it) {
            var b = base[it.uid];
            return { uid: it.uid, x: b.x, y: b.y, w: b.w, h: b.h };
        });
        rects = place(rest, fixed);
    } else {
        // over (also the fallback for an unknown mode)
        for (k in base)
            rects[k] = copy(base[k]);
        rects[expanded.uid] = {
            x: anchor(r.x, r.w, w, grid.cols),
            y: anchor(r.y, r.h, h, grid.rows),
            w: w,
            h: h,
            z: 1,
            hidden: false
        };
    }

    var out = bounds(rects);
    return { rects: rects, cols: out.cols, rows: out.rows };
}

// Positions after dropping item `uid` (in `items` or new) at x/y with size w×h: it stays exactly
// there and the others are re-placed around it by the base pass (pushed down).
// → { uid: { x, y } } for every item, so what's saved is what's shown.
function drop(items, uid, x, y, w, h) {
    var fixed = {};
    fixed[uid] = { x: Math.max(0, x | 0), y: Math.max(0, y | 0), w: Math.max(1, w | 0), h: Math.max(1, h | 0), z: 0, hidden: false };
    // the others from where they are now (already collision-free among themselves)
    var others = items.filter(function (it) {
        return it.uid !== uid;
    });
    var now = place(others, {});
    var rest = others.map(function (it) {
        var r = now[it.uid];
        return { uid: it.uid, x: r.x, y: r.y, w: r.w, h: r.h };
    });
    var rects = place(rest, fixed);
    var out = {};
    for (var k in rects)
        out[k] = { x: rects[k].x, y: rects[k].y };
    return out;
}

// the size in `sizes` ("WxH" strings) closest to w×h; ties go to the smaller area
function nearestSize(sizes, w, h) {
    var best = null, bestDist = Infinity, bestArea = Infinity;
    sizes.forEach(function (s) {
        var m = /^(\d+)x(\d+)$/.exec(String(s));
        if (!m)
            return;
        var sw = parseInt(m[1]), sh = parseInt(m[2]);
        var d = Math.hypot(sw - w, sh - h);
        var area = sw * sh;
        if (d < bestDist - 1e-9 || (Math.abs(d - bestDist) < 1e-9 && area < bestArea)) {
            best = s;
            bestDist = d;
            bestArea = area;
        }
    });
    return best;
}

// the first spot (row by row, left to right) where a w×h item fits among `items` inside
// max(cols, w) columns; there's always one below everything
function firstFree(items, w, h, cols) {
    var placed = place(items, {});
    var list = [];
    var bottom = 0;
    for (var k in placed) {
        list.push(placed[k]);
        bottom = Math.max(bottom, placed[k].y + placed[k].h);
    }
    var width = Math.max(cols | 0, w);
    for (var y = 0; y <= bottom; y++) {
        for (var x = 0; x + w <= width; x++) {
            var r = { x: x, y: y, w: w, h: h };
            if (!list.some(function (p) {
                return overlaps(r, p);
            }))
                return { x: x, y: y };
        }
    }
    return { x: 0, y: bottom };
}
