import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { syncHyprlandFiles } from "../../cli/lib/hyprland-write.js";

// Only the two refusal paths, both of which return before syncHyprlandFiles
// ever reaches `hyprctl reload` — on purpose. This process inherits
// whatever real HYPRLAND_INSTANCE_SIGNATURE the shell running `node --test`
// sits in, so a test that reached the write+reload path here would reload
// Theo's real session, exactly what this step's own risk warns about. The
// full write-then-reload path (consent on, hypr folder present) is only
// ever exercised in tests/cli/hyprland.sh, inside the nested compositor,
// where HYPRLAND_INSTANCE_SIGNATURE points at the disposable instance
// instead — see that file and tests/README.md.
function withXdg(fn) {
    const saved = process.env.XDG_CONFIG_HOME;
    const dir = mkdtempSync(join(tmpdir(), "vtnc-hyprland-write-"));
    process.env.XDG_CONFIG_HOME = dir;
    try {
        return fn(dir);
    } finally {
        if (saved === undefined) delete process.env.XDG_CONFIG_HOME;
        else process.env.XDG_CONFIG_HOME = saved;
        rmSync(dir, { recursive: true, force: true });
    }
}

test("without consent, nothing is written at all — decision 10.3b", () => {
    withXdg((dir) => {
        const result = syncHyprlandFiles({ hyprland: { enabled: false, keybinds: [{ key: "SUPER + Q", commands: ["kitty"], enabled: true }] } });
        assert.equal(result.written, false);
        assert.equal(result.reason, "disabled");
        assert.ok(!existsSync(join(dir, "hypr")));
    });
});

test("with consent but no ~/.config/hypr folder, it refuses rather than creating one blindly", () => {
    withXdg((dir) => {
        const result = syncHyprlandFiles({ hyprland: { enabled: true, keybinds: [] } });
        assert.equal(result.written, false);
        assert.equal(result.reason, "no-hypr-folder");
        assert.ok(!existsSync(join(dir, "hypr")));
    });
});
