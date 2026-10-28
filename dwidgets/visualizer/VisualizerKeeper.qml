pragma Singleton
import QtQuick
import Quickshell
import qs.core
import qs.services

// Keeps cava running for the dashboard's Visualizer Dwidgets while music plays, with the dashboard closed
// too (2026-10-27, user: each open waited 1–3 s for cava to start again). It holds one cava per bar count
// placed (Store.dashboard, not off), from the shell's start (shell.qml touches it), while something plays
// and a few seconds after it stops; the Dwidgets' own acquire / release ride on top of it.
Singleton {
    id: root

    // playing, held 10 s after it stops (a pause or a track change doesn't stop cava)
    property bool playing: MprisController.isPlaying
    Connections {
        target: MprisController
        function onIsPlayingChanged() {
            if (MprisController.isPlaying) {
                stopDelay.stop();
                root.playing = true;
            } else {
                stopDelay.restart();
            }
        }
    }
    Timer {
        id: stopDelay
        interval: 10000
        onTriggered: root.playing = MprisController.isPlaying
    }

    // the bar counts placed on the dashboard
    readonly property var counts: {
        const out = [];
        for (const w of Store.dashboard?.widgets ?? []) {
            if (w.id !== "visualizer" || w.off)
                continue;
            const n = Math.max(4, Math.min(48, w.options?.bars ?? 16));
            if (!out.includes(n))
                out.push(n);
        }
        return out;
    }
    readonly property var wanted: playing ? counts : []

    property var held: []
    function sync() {
        for (const n of wanted.filter(n => !held.includes(n)))
            Cava.acquire(n);
        for (const n of held.filter(n => !wanted.includes(n)))
            Cava.release(n);
        held = wanted.slice();
    }
    onWantedChanged: sync()
    Component.onCompleted: sync()
}
