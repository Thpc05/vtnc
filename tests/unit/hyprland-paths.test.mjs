import { test } from "node:test";
import assert from "node:assert/strict";
import { homedir } from "node:os";
import { join } from "node:path";
import { hyprParentDir, hyprVtncDir, hyprKeybindsFile } from "../../cli/lib/hyprland-paths.js";

// No VTNC_*-style override here (unlike cli/lib/paths.js) — this is the
// real, standard XDG location, so a test has to redirect the real
// XDG_CONFIG_HOME or HOME and then check the path these functions actually
// resolve to, exactly as a test against the real nested compositor must
// (see tests/cli/hyprland.sh and AGENTS.md's warning for this step).
test("hyprParentDir follows XDG_CONFIG_HOME when it's set", () => {
    const saved = process.env.XDG_CONFIG_HOME;
    process.env.XDG_CONFIG_HOME = "/tmp/vtnc-test-xdg";
    try {
        assert.equal(hyprParentDir(), "/tmp/vtnc-test-xdg/hypr");
    } finally {
        if (saved === undefined) delete process.env.XDG_CONFIG_HOME;
        else process.env.XDG_CONFIG_HOME = saved;
    }
});

test("hyprParentDir falls back to $HOME/.config when XDG_CONFIG_HOME is unset", () => {
    const saved = process.env.XDG_CONFIG_HOME;
    delete process.env.XDG_CONFIG_HOME;
    try {
        assert.equal(hyprParentDir(), join(homedir(), ".config", "hypr"));
    } finally {
        if (saved !== undefined) process.env.XDG_CONFIG_HOME = saved;
    }
});

test("hyprVtncDir/hyprKeybindsFile nest under hyprParentDir", () => {
    const saved = process.env.XDG_CONFIG_HOME;
    process.env.XDG_CONFIG_HOME = "/tmp/vtnc-test-xdg";
    try {
        assert.equal(hyprVtncDir(), "/tmp/vtnc-test-xdg/hypr/vtnc");
        assert.equal(hyprKeybindsFile(), "/tmp/vtnc-test-xdg/hypr/vtnc/keybinds.lua");
    } finally {
        if (saved === undefined) delete process.env.XDG_CONFIG_HOME;
        else process.env.XDG_CONFIG_HOME = saved;
    }
});
