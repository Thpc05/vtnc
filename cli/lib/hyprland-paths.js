import { join } from "node:path";
import { homedir } from "node:os";

// 0.507 is the first step that writes outside vtnc's own config folder, at
// the user's real ~/.config/hypr (or wherever XDG_CONFIG_HOME points) —
// unlike paths.js above, there is deliberately no VTNC_*-style override
// here: this is a real, standard XDG location, not a vtnc-specific one, so
// a test redirects the real HOME or XDG_CONFIG_HOME (as AGENTS.md's own
// wording for this step says), then checks the path these functions
// actually resolve to — never just that the env var looks overridden.
export function hyprParentDir() {
    const xdg = process.env.XDG_CONFIG_HOME;
    const base = xdg || join(homedir(), ".config");
    return join(base, "hypr");
}

export function hyprVtncDir() {
    return join(hyprParentDir(), "vtnc");
}

export function hyprKeybindsFile() {
    return join(hyprVtncDir(), "keybinds.lua");
}

// O ponto de entrada do vtnc dentro da pasta dele. O usuario cola
// `pcall(require, "vtnc")` uma vez no hyprland.lua e nunca mais mexe: quando
// o vtnc passar a gerar outros arquivos, eles entram atras deste init
// (decisao 7.6).
export function hyprInitFile() {
    return join(hyprVtncDir(), "init.lua");
}
