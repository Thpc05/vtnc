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
