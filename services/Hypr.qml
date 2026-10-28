pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme

// Thin wrapper over Quickshell.Hyprland so the rest of the shell
// doesn't depend on the compositor API directly.
Singleton {
    id: root

    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    readonly property string focusedScreen: focusedMonitor?.name ?? ""
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel
    readonly property var workspaces: Hyprland.workspaces.values
    // HyprlandWorkspace.toplevels.values doesn't notify bindings when windows appear,
    // so window membership is derived from the global list instead.
    readonly property var toplevels: Hyprland.toplevels.values

    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return screen ? Hyprland.monitorFor(screen) : null;
    }

    function hasFullscreen(screen: ShellScreen): bool {
        return monitorFor(screen)?.activeWorkspace?.hasFullscreen ?? false;
    }

    function workspace(id: int): HyprlandWorkspace {
        return workspaces.find(w => w.id === id) ?? null;
    }

    function windowsOn(id: int): var {
        return toplevels.filter(t => t.workspace?.id === id);
    }

    function isOccupied(id: int): bool {
        return toplevels.some(t => t.workspace?.id === id);
    }

    // Hyprland >= 0.55 with a Lua config only accepts Lua dispatchers
    // (`hl.dsp.focus({ workspace = "3" })`); the legacy `workspace 3` form errors out.
    // HyprlandWorkspace.activate() still sends the legacy form, so don't use it.
    function dispatch(lua: string, legacy: string) {
        Hyprland.dispatch(Hyprland.usingLua ? lua : legacy);
    }

    function focusWorkspace(id: int) {
        dispatch(`hl.dsp.focus({ workspace = "${id}" })`, `workspace ${id}`);
    }

    function focusWorkspaceRelative(delta: int) {
        const rel = delta > 0 ? `+${delta}` : `${delta}`;
        dispatch(`hl.dsp.focus({ workspace = "r${rel}" })`, `workspace r${rel}`);
    }

    // The blur behind the shell's layers follows Appearance → Transparency (as caelestia's
    // Colours.reloadHyprRules): blur on only while transparent, and ignore_alpha just under the
    // page's alpha, so the shadow and soft edges stay sharp. Set at runtime (hyprctl eval), since
    // the values change live; re-applied after Hyprland reloads its config (which drops them).
    readonly property var blurNamespaces: ["^vtnc$"]

    function applyBlurRules() {
        const on = Colors.transparency.enabled;
        const ignore = Math.max(0, Colors.transparency.base - 0.03).toFixed(2);
        const rules = blurNamespaces.map(ns => on ? `hl.layer_rule({ match = { namespace = "${ns}" }, blur = true, blur_popups = true, ignore_alpha = ${ignore} })` : `hl.layer_rule({ match = { namespace = "${ns}" }, blur = false, blur_popups = false })`);
        if (Hyprland.usingLua)
            Quickshell.execDetached(["hyprctl", "eval", rules.join("\n")]);
        else
            Quickshell.execDetached(["hyprctl", "--batch", blurNamespaces.map(ns => `keyword layerrule blur ${on ? 1 : 0}, match:namespace ${ns}; keyword layerrule ignore_alpha ${ignore}, match:namespace ${ns}`).join("; ")]);
    }

    Component.onCompleted: blurDebounce.restart()

    Connections {
        target: Colors.transparency
        function onEnabledChanged() {
            blurDebounce.restart();
        }
        function onBaseChanged() {
            blurDebounce.restart();
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent) {
            if (event.name === "configreloaded")
                blurDebounce.restart();
        }
    }

    // a stepper held down changes `base` many times: one call at the end
    Timer {
        id: blurDebounce
        interval: 300
        onTriggered: root.applyBlurRules()
    }
}
