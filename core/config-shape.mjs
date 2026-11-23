// Pure shape helpers for the config document: defaults and lookups, no I/O.
// Shared between the CLI (node) and the shell (QML import as ECMAScript
// module) so the two never disagree about what a valid config looks like.

export function defaultConfig() {
    return {
        cell: { base: 8 },
        monitors: {},
        islands: [],
        pages: {},
        autohide: defaultAutohide(),
    };
}

// The global autohide defaults (0.505, decision 11.2c/12.4): enabled/mode
// are the fallback an island uses when it doesn't set its own autohide/
// autohideMode; distance is global-only, never per-island (12.4). fade/
// slideSpeed/shrinkSize tune the two animations (11.2b) but, unlike the
// three above, don't get a CLI verb or a Settings control in 0.505 — the
// step's own scope names only "os atributos [autohide, autohideMode] e a
// distância" as entering the CLI and the Settings page; the rest is a
// config.json-only knob for now, not the "resto do sistema de animação"
// that's explicitly out of scope.
export function defaultAutohide() {
    return { enabled: false, mode: "always", distance: 2, fade: 150, slideSpeed: 150, shrinkSize: 1 };
}

// island.autohide / island.autohideMode are optional overrides (decision
// 11.2c): absent means "use the global value". Resolving them here, once,
// keeps that fallback in one place for the CLI's `get`/`list` and for
// Island.qml alike.
export function resolveAutohide(config, island) {
    const global = config.autohide ?? defaultAutohide();
    return {
        enabled: island.autohide ?? global.enabled ?? false,
        mode: island.autohideMode ?? global.mode ?? "always",
    };
}

// The page lifecycle (0.506, decisions 1e.0/1e.1/1e.2/1e.4/1e.5): how a
// called page behaves once it's on top of an island's stack. Declared on
// the page itself, not the island (1e.1) — a page is "called" by default,
// "popup" adds the auto-dismiss timer and the corner close button, "lock"
// ignores Esc and the click-outside watcher below (1e.4's exception) and
// only ever leaves by the CLI's own `island <name> end` (or another call
// replacing it). "idle" isn't a lifecycle a page declares — it's just
// whatever island.page points at, with nothing on the stack above it.
export const PAGE_LIFECYCLES = ["called", "popup", "lock"];

export function pageLifecycle(page) {
    return page?.lifecycle ?? "called";
}

// Decision 1e.5: a page declares whether it needs the keyboard; only a page
// that says yes steals it (WlrKeyboardFocus.Exclusive in island/Island.qml)
// while it's on top. Everything else gets OnDemand — eligible for focus
// once the user clicks into it, never grabbed outright.
export function pageNeedsKeyboard(page) {
    return page?.needsKeyboard ?? false;
}

// How long a "popup" lifecycle page stays up before it dismisses itself
// (decision 1e.0's "some por tempo"). Only read when pageLifecycle(page)
// is "popup" — called/lock pages ignore it entirely.
export function pagePopupTimeout(page) {
    return page?.popupTimeout ?? 5000;
}

// The call stack an island's mirror renders from (decision 1e.2): invoking
// a page pushes it, keeping at most this many entries — the oldest falls
// off the bottom first, never the page just invoked.
export const CALL_STACK_LIMIT = 5;

export function pushCall(stack, pageName) {
    return [...(stack ?? []), pageName].slice(-CALL_STACK_LIMIT);
}

// Unstacking: drop the top entry. An empty result means "back to idle" —
// island/Island.qml's currentPageName falls back there on its own, nothing
// special-cased here.
export function popCall(stack) {
    return (stack ?? []).slice(0, -1);
}

export function topOfCall(stack) {
    const current = stack ?? [];
    return current.length > 0 ? current[current.length - 1] : "";
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
export const ISLAND_SETTABLE_KEYS = ["page", "layer", "anchor", "offset", "size", "gap", "autohide", "autohideMode"];
export const VALID_LAYERS = ["background", "bottom", "top", "overlay"];
export const ANCHOR_EDGES = ["top", "bottom", "left", "right"];
export const AUTOHIDE_MODES = ["always", "window", "fullscreen"];

// What `vtnc autohide set` accepts — the global side of decision 11.2c/
// 12.4, the same closed-list pattern as ISLAND_SETTABLE_KEYS.
export const AUTOHIDE_GLOBAL_KEYS = ["enabled", "mode", "distance"];

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
    if (key === "autohide") {
        if (raw === "true") return true;
        if (raw === "false") return false;
        return undefined;
    }
    return raw; // layer, page, autohideMode: plain strings already
}

// Same shape as parseIslandSetValue, for the global `vtnc autohide set`
// (0.505). Kept separate because the two closed key lists don't overlap
// and mixing them would let a typo'd namespace silently parse the other
// one's keys.
export function parseAutohideGlobalValue(key, raw) {
    if (key === "enabled") {
        if (raw === "true") return true;
        if (raw === "false") return false;
        return undefined;
    }
    if (key === "distance") {
        return Number(raw);
    }
    return raw; // mode
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

    if (key === "autohide") {
        return typeof value === "boolean" ? null : `invalid autohide: must be true or false`;
    }

    if (key === "autohideMode") {
        return AUTOHIDE_MODES.includes(value) ? null : `invalid autohideMode: "${value}" (must be one of: ${AUTOHIDE_MODES.join(", ")})`;
    }

    return null;
}

// Returns an error string, or null if `value` (already run through
// parseAutohideGlobalValue) is fine for `key` on the global autohide
// config (0.505, decision 12.4: distance is global-only, never per-island).
export function validateAutohideGlobalSet(key, value) {
    if (!AUTOHIDE_GLOBAL_KEYS.includes(key)) {
        return `unknown key "${key}" for autohide set (try: ${AUTOHIDE_GLOBAL_KEYS.join(", ")})`;
    }
    if (key === "enabled") {
        return typeof value === "boolean" ? null : `invalid enabled: must be true or false`;
    }
    if (key === "mode") {
        return AUTOHIDE_MODES.includes(value) ? null : `invalid mode: "${value}" (must be one of: ${AUTOHIDE_MODES.join(", ")})`;
    }
    if (key === "distance") {
        return Number.isInteger(value) && value >= 0 ? null : `invalid distance: must be a whole number of cells, zero or more`;
    }
    return null;
}
