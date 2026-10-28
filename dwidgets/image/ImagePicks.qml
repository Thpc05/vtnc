pragma Singleton
import QtQuick
import Quickshell

// What each folder Image Dwidget shows (2026-10-27, user), kept while the shell runs: the dashboard makes
// its Dwidgets again on each open, so "once per start" and the timer need the pick to outlive them.
// uid → { folder, path, time, opens } (time: when it was picked, ms; opens: DashboardShape.opens then).
Singleton {
    id: root

    property var picks: ({})

    function get(uid: string): var {
        return picks[uid] ?? null;
    }
    function set(uid: string, folder: string, path: string, opens: int) {
        const next = Object.assign({}, picks);
        next[uid] = {
            folder: folder,
            path: path,
            time: Date.now(),
            opens: opens
        };
        picks = next;
    }
}
