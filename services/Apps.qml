pragma Singleton

import QtQuick
import Quickshell
import qs.core

// Desktop applications + search for the launcher.
// Ranking: exact/prefix/word matches on the name, then generic name / keywords / comment,
// then fuzzy subsequence; launch count (persisted in apps.launcher.usage) breaks ties.
Singleton {
    id: root

    readonly property var entries: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    readonly property var usage: Store.appGet("launcher", "usage", {})

    // freedesktop categories → a Material symbol (the first that matches, in this order); the active
    // window's Tone and the workspaces' window icons
    readonly property var categorySymbols: [["WebBrowser", "language"], ["TerminalEmulator", "terminal"], ["IDE", "code"], ["Development", "code"], ["TextEditor", "edit_note"], ["Game", "sports_esports"], ["Music", "music_note"], ["Audio", "music_note"], ["Video", "movie"], ["AudioVideo", "play_circle"], ["Graphics", "palette"], ["FileManager", "folder"], ["Filesystem", "folder"], ["Chat", "chat"], ["InstantMessaging", "chat"], ["Email", "mail"], ["Network", "public"], ["Office", "description"], ["Settings", "settings"], ["System", "computer"], ["Utility", "build"]]
    function categorySymbol(categories: var): string {
        for (const [key, value] of categorySymbols)
            if (categories.includes(key))
                return value;
        return "web_asset";
    }

    function usageOf(entry: DesktopEntry): int {
        return usage[entry.id] ?? 0;
    }

    function fuzzy(text: string, q: string): int {
        // subsequence match; tighter matches score higher
        let ti = 0, gaps = 0, last = -1;
        for (const ch of q) {
            const i = text.indexOf(ch, ti);
            if (i < 0)
                return 0;
            if (last >= 0)
                gaps += i - last - 1;
            last = i;
            ti = i + 1;
        }
        return Math.max(1, 30 - gaps);
    }

    function score(entry: DesktopEntry, q: string): int {
        const name = entry.name.toLowerCase();
        if (name === q)
            return 1000;
        if (name.startsWith(q))
            return 800;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 600;
        if (name.includes(q))
            return 400;
        const extra = [entry.genericName, entry.comment, ...(entry.keywords ?? []), entry.id].join(" ").toLowerCase();
        if (extra.includes(q))
            return 200;
        return fuzzy(name, q);
    }

    // QML's Array.sort isn't stable, so every comparator ends with the name
    function byName(a: DesktopEntry, b: DesktopEntry): int {
        return a.name.localeCompare(b.name);
    }

    function query(text: string): var {
        const q = text.trim().toLowerCase();
        if (q === "")
            return entries.slice().sort((a, b) => (usageOf(b) - usageOf(a)) || byName(a, b));
        return entries.map(e => ({
                    e: e,
                    s: score(e, q) + Math.min(usageOf(e), 50)
                })).filter(r => r.s > Math.min(usageOf(r.e), 50)).sort((a, b) => (b.s - a.s) || byName(a.e, b.e)).map(r => r.e);
    }

    function launch(entry: DesktopEntry) {
        count(entry);
        entry.execute();
    }

    // one of the entry's desktop actions (New Private Window…; the launcher's hero)
    function launchAction(entry: DesktopEntry, action: DesktopAction) {
        count(entry);
        action.execute();
    }

    function count(entry: DesktopEntry) {
        const u = Object.assign({}, usage);
        u[entry.id] = (u[entry.id] ?? 0) + 1;
        Store.appSet("launcher", "usage", u);
    }
}
