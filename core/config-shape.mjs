// Pure shape helpers for the config document: defaults and lookups, no I/O.
// Shared between the CLI (node) and the shell (QML import as ECMAScript
// module) so the two never disagree about what a valid config looks like.

export function defaultConfig() {
    return {
        cell: { base: 8 },
        monitors: {},
        islands: [],
        pages: {},
    };
}

export function findIsland(config, name) {
    return (config.islands ?? []).find((island) => island.name === name);
}

export function findPage(config, name) {
    return (config.pages ?? {})[name];
}

export function listIslands(config) {
    return config.islands ?? [];
}

// What the CLI's `set` accepts on an island, and what makes a value valid
// (decision 0.502i: a fixed list, not inferred from the config's shape — an
// unknown key or a value pointing at something that doesn't exist is
// refused, config.json stays untouched). 0.503 adds anchor/offset/size;
// 0.504 adds gap — exactly what the Settings Islands page needs, nothing
// more.
export const ISLAND_SETTABLE_KEYS = ["page", "layer", "anchor", "offset", "size", "gap"];
export const VALID_LAYERS = ["background", "bottom", "top", "overlay"];
export const ANCHOR_EDGES = ["top", "bottom", "left", "right"];

// anchor/offset/size travel through the CLI as a single JSON-encoded
// argument (they're objects, not scalars like page/layer); this turns the
// raw command-line string into the value validateIslandSet checks and
// island[key] eventually stores. Invalid JSON becomes undefined, which the
// shape checks below already reject with a clear message — no special case
// needed for "that wasn't JSON at all". gap (0.504) is a plain number, one
// cell count, never four sides (decision 2d.3) — Number() on a non-numeric
// string gives NaN, which the gap check below also rejects on its own.
export function parseIslandSetValue(key, raw) {
    if (key === "anchor" || key === "offset" || key === "size") {
        try {
            return JSON.parse(raw);
        } catch (error) {
            return undefined;
        }
    }
    if (key === "gap") {
        return Number(raw);
    }
    return raw;
}

function isPlainObject(value) {
    return typeof value === "object" && value !== null && !Array.isArray(value);
}

// Returns an error string, or null if `value` (already run through
// parseIslandSetValue) is fine for `key` on an island in this `config`.
export function validateIslandSet(key, value, config) {
    if (!ISLAND_SETTABLE_KEYS.includes(key)) {
        return `unknown key "${key}" for island set (try: ${ISLAND_SETTABLE_KEYS.join(", ")})`;
    }

    if (key === "page") {
        return findPage(config, value) ? null : `no such page: "${value}"`;
    }

    if (key === "layer") {
        return VALID_LAYERS.includes(value) ? null : `invalid layer: "${value}" (must be one of: ${VALID_LAYERS.join(", ")})`;
    }

    if (key === "anchor") {
        if (!isPlainObject(value)) return `invalid anchor: must be a JSON object, e.g. {"top":true,"left":true}`;
        for (const edge of Object.keys(value)) {
            if (!ANCHOR_EDGES.includes(edge)) return `invalid anchor: unknown edge "${edge}" (must be one of: ${ANCHOR_EDGES.join(", ")})`;
            if (typeof value[edge] !== "boolean") return `invalid anchor: "${edge}" must be true or false`;
        }
        return null;
    }

    if (key === "offset" || key === "size") {
        const fields = key === "offset" ? ["x", "y"] : ["w", "h"];
        if (!isPlainObject(value)) return `invalid ${key}: must be a JSON object with ${fields.join(" and ")}`;
        for (const field of fields) {
            if (typeof value[field] !== "number" || !Number.isFinite(value[field])) {
                return `invalid ${key}: "${field}" must be a number`;
            }
            if (key === "size" && value[field] <= 0) return `invalid size: "${field}" must be greater than zero`;
        }
        return null;
    }

    if (key === "gap") {
        return Number.isInteger(value) && value >= 0 ? null : `invalid gap: must be a whole number of cells, zero or more`;
    }

    return null;
}
