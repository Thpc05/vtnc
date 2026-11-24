import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { hyprParentDir, hyprVtncDir, hyprKeybindsFile, hyprInitFile } from "./hyprland-paths.js";
import { generateKeybindsLua, generateInitLua } from "../../core/hyprland-lua.mjs";
import { defaultHyprland } from "../../core/config-shape.mjs";

// Writes ~/.config/hypr/vtnc/keybinds.lua and reloads Hyprland (decisions
// 7.2/7.3). Called by `vtnc hyprland generate`, which core/HyprlandSync.qml
// spawns from the running shell whenever config.hyprland changes — "a shell
// roda hyprctl reload sozinha" is this call, made by the shell, not by
// `vtnc hyprland set` itself (decision 4b.4: `set` only ever writes
// config.json, same as every other namespace).
//
// Consent (decision 10.3b) is checked again here, even though the shell's
// own watcher already checks before ever spawning this — nothing written
// without `enabled: true`, no matter how this gets invoked. The existence
// check on ~/.config/hypr (not vtnc's own subfolder inside it) is the
// second gate: that folder existing is what tells vtnc Hyprland is actually
// set up on this machine, so vtnc never creates it blindly.
export function syncHyprlandFiles(config) {
    const hyprland = config.hyprland ?? defaultHyprland();
    if (!hyprland.enabled) {
        return { written: false, reason: "disabled" };
    }

    const parent = hyprParentDir();
    if (!existsSync(parent)) {
        return { written: false, reason: "no-hypr-folder", path: parent };
    }

    const file = hyprKeybindsFile();
    mkdirSync(hyprVtncDir(), { recursive: true });
    writeFileSync(file, generateKeybindsLua(hyprland));
    // O init vai junto, sempre inteiro como todo arquivo gerado (7.2): e ele
    // que o hyprland.lua do usuario nomeia, e e o que deixa o vtnc ganhar
    // outros arquivos sem ele reeditar nada (7.6).
    writeFileSync(hyprInitFile(), generateInitLua());

    try {
        execFileSync("hyprctl", ["reload"], { encoding: "utf8" });
        return { written: true, reloaded: true, path: file, init: hyprInitFile() };
    } catch (error) {
        return { written: true, reloaded: false, reloadError: error.message, path: file, init: hyprInitFile() };
    }
}
