pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs.theme
import "launch.js" as L

// Opens launch targets (core/launch.js: vtnc:<app>, vtnc:settings/<page>, desktop:<entry id>), for the
// App / Settings Qwidgets, IPC (`launch run <target>`) and, later, dashboard tabs and the CLI.
Singleton {
    id: root

    readonly property var vtncApps: L.VTNC_APPS

    function valid(target: string): bool {
        return L.parse(target) !== null && (L.parse(target).kind !== "desktop" || entry(target) !== null);
    }

    // the desktop entry of a desktop: target (null for others / unknown)
    function entry(target: string): var {
        const t = L.parse(target);
        if (!t || t.kind !== "desktop")
            return null;
        return DesktopEntries.byId(t.id) ?? DesktopEntries.heuristicLookup(t.id) ?? null;
    }

    // how to show it: { title, symbol (a Material Symbols name), image (an icon path, desktop apps) }
    function describe(target: string): var {
        const t = L.parse(target);
        if (!t)
            return {
                title: "Pick an app",
                symbol: "apps",
                image: ""
            };
        if (t.kind === "vtnc") {
            const app = L.VTNC_APPS[t.id];
            return {
                title: app.title,
                symbol: Icons[app.icon] ?? "apps",
                image: ""
            };
        }
        const e = entry(target);
        return {
            title: e?.name ?? t.id,
            symbol: "apps",
            image: e ? Quickshell.iconPath(e.icon || t.id, true) : ""
        };
    }

    function run(target: string) {
        const t = L.parse(target);
        if (!t)
            return;
        if (t.kind === "vtnc") {
            Runtime.openApp(t.id, t.arg !== "" ? {
                page: t.arg
            } : {});
            return;
        }
        const e = entry(target);
        if (e)
            Runtime.closeThen(() => Apps.launch(e));
    }

    // a target from its parts (the picker)
    function format(kind: string, id: string, arg: string): string {
        return L.format(kind, id, arg);
    }
}
