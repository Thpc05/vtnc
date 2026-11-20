import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname } from "node:path";
import { configFile } from "./paths.js";
import { defaultConfig } from "../../core/config-shape.mjs";

export function readConfig() {
    const file = configFile();
    if (!existsSync(file)) return defaultConfig();
    return JSON.parse(readFileSync(file, "utf8"));
}

// `set` writes straight to the file (decision 4b.4): the shell's own
// FileView (watchChanges: true) is what picks this up live, so the CLI
// doesn't need the shell to be running at all for `set`.
export function writeConfig(config) {
    const file = configFile();
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, JSON.stringify(config, null, 2) + "\n");
}
