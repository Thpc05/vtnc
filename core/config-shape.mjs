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
// (decision 5.4's principle — an invalid config is never applied — carried
// over from Settings to the CLI: a `set` that would leave config.json
// pointing at something that doesn't exist is refused, not written).
export const ISLAND_SETTABLE_KEYS = ["page", "layer"];
export const VALID_LAYERS = ["background", "bottom", "top", "overlay"];

// Returns an error string, or null if `value` is fine for `key` on an
// island in this `config`.
export function validateIslandSet(key, value, config) {
    if (!ISLAND_SETTABLE_KEYS.includes(key)) {
        return `unknown key "${key}" for island set (try: ${ISLAND_SETTABLE_KEYS.join(", ")})`;
    }
    if (key === "page" && !findPage(config, value)) {
        return `no such page: "${value}"`;
    }
    if (key === "layer" && !VALID_LAYERS.includes(value)) {
        return `invalid layer: "${value}" (must be one of: ${VALID_LAYERS.join(", ")})`;
    }
    return null;
}
