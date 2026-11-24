import { test } from "node:test";
import assert from "node:assert/strict";
import {
    defaultHyprland, validateHyprlandSet, parseHyprlandSetValue,
} from "../../core/config-shape.mjs";
import { managedKeys, enabledKeybinds, generateKeybindsLua, generateInitLua, VTNC_LUA_PARTS } from "../../core/hyprland-lua.mjs";

test("defaultHyprland starts with consent off and no keybinds", () => {
    assert.deepEqual(defaultHyprland(), { enabled: false, keybinds: [] });
});

test("set enabled only accepts true/false", () => {
    assert.equal(validateHyprlandSet("enabled", true), null);
    assert.match(validateHyprlandSet("enabled", "true"), /must be true or false/);
});

test("set on an unknown key is refused", () => {
    assert.match(validateHyprlandSet("banana", "7"), /unknown key/);
});

test("set keybinds requires an array of well-shaped entries", () => {
    const good = [{ key: "SUPER + Q", commands: ["kitty"], enabled: true }];
    assert.equal(validateHyprlandSet("keybinds", good), null);
});

test("set keybinds refuses a non-array, or an entry missing a required field", () => {
    assert.match(validateHyprlandSet("keybinds", {}), /must be a JSON array/);
    assert.match(validateHyprlandSet("keybinds", [{ commands: ["kitty"], enabled: true }]), /invalid keybinds/);
    assert.match(validateHyprlandSet("keybinds", [{ key: "", commands: ["kitty"], enabled: true }]), /invalid keybinds/);
    assert.match(validateHyprlandSet("keybinds", [{ key: "SUPER + Q", commands: "kitty", enabled: true }]), /invalid keybinds/);
    assert.match(validateHyprlandSet("keybinds", [{ key: "SUPER + Q", commands: ["kitty"] }]), /invalid keybinds/);
});

test("set keybinds accepts an optional description, but only as a string", () => {
    const withDescription = [{ key: "SUPER + Q", commands: ["kitty"], enabled: true, description: "terminal" }];
    assert.equal(validateHyprlandSet("keybinds", withDescription), null);
    const badDescription = [{ key: "SUPER + Q", commands: ["kitty"], enabled: true, description: 7 }];
    assert.match(validateHyprlandSet("keybinds", badDescription), /invalid keybinds/);
});

test("parseHyprlandSetValue decodes booleans and JSON for their own keys", () => {
    assert.equal(parseHyprlandSetValue("enabled", "true"), true);
    assert.equal(parseHyprlandSetValue("enabled", "false"), false);
    assert.equal(parseHyprlandSetValue("enabled", "sideways"), undefined);
    assert.deepEqual(parseHyprlandSetValue("keybinds", '[{"key":"a"}]'), [{ key: "a" }]);
    assert.equal(parseHyprlandSetValue("keybinds", "not json"), undefined);
});

test("managedKeys lists every distinct key, enabled or not, in first-seen order", () => {
    const hyprland = {
        keybinds: [
            { key: "SUPER + Q", commands: ["a"], enabled: true },
            { key: "SUPER + W", commands: ["b"], enabled: false },
            { key: "SUPER + Q", commands: ["c"], enabled: true },
        ],
    };
    assert.deepEqual(managedKeys(hyprland), ["SUPER + Q", "SUPER + W"]);
});

test("enabledKeybinds drops the disabled ones, keeps the rest in order", () => {
    const hyprland = {
        keybinds: [
            { key: "SUPER + Q", commands: ["a"], enabled: true },
            { key: "SUPER + W", commands: ["b"], enabled: false },
        ],
    };
    assert.deepEqual(enabledKeybinds(hyprland).map((k) => k.key), ["SUPER + Q"]);
});

test("generateKeybindsLua unbinds every managed key before binding the enabled ones", () => {
    const hyprland = {
        keybinds: [
            { key: "SUPER + Q", commands: ["kitty"], enabled: true },
            { key: "SUPER + W", commands: ["firefox"], enabled: false },
        ],
    };
    const lua = generateKeybindsLua(hyprland);
    const unbindQ = lua.indexOf("hl.unbind([[SUPER + Q]])");
    const unbindW = lua.indexOf("hl.unbind([[SUPER + W]])");
    const bindQ = lua.indexOf("hl.bind([[SUPER + Q]]");
    assert.ok(unbindQ >= 0 && unbindW >= 0, "both keys get unbound");
    assert.ok(bindQ > unbindW, "every unbind happens before any bind");
    assert.ok(!lua.includes("hl.bind([[SUPER + W]]"), "a disabled key is never (re)bound");
});

test("generateKeybindsLua joins a keybind's command list into one exec_cmd call", () => {
    const hyprland = { keybinds: [{ key: "SUPER + Q", commands: ["one", "two"], enabled: true }] };
    const lua = generateKeybindsLua(hyprland);
    assert.ok(lua.includes('hl.dsp.exec_cmd([[one; two]])'));
});

test("generateKeybindsLua carries the DO NOT EDIT warning", () => {
    assert.match(generateKeybindsLua(defaultHyprland()), /DO NOT EDIT/);
});

test("generateKeybindsLua with no keybinds at all still produces a valid, empty-of-binds file", () => {
    const lua = generateKeybindsLua(defaultHyprland());
    assert.ok(!lua.includes("hl.bind("));
    assert.ok(!lua.includes("hl.unbind("));
});

// 7.6: o usuario nomeia o init, nao cada arquivo. Se uma parte nova entrar
// em VTNC_LUA_PARTS num passo futuro, ela tem de aparecer sozinha aqui, sem
// ninguem reeditar o hyprland.lua.
test("generateInitLua requires every part vtnc generates, and carries the warning", () => {
    const lua = generateInitLua();
    assert.match(lua, /DO NOT EDIT/i);
    for (const part of VTNC_LUA_PARTS) {
        assert.ok(lua.includes(`require("vtnc/${part}")`), `faltou a parte ${part}`);
    }
});

test("generateInitLua names keybinds today, and nothing the generator doesn't write", () => {
    assert.deepEqual(VTNC_LUA_PARTS, ["keybinds"]);
    const required = [...generateInitLua().matchAll(/require\("vtnc\/([a-z-]+)"\)/g)].map((m) => m[1]);
    assert.deepEqual(required, VTNC_LUA_PARTS);
});
