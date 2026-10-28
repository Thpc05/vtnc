import QtQuick
import qs.core

// The Dino run summary's data (2026-10-27, user): the high score (the badge's number) and the last runs
// (state.json apps.dino.runs, newest first; the best one marked). A click opens the game; ▶ opens it on a
// new run.
QtObject {
    id: root

    readonly property string title: "Dino run"
    readonly property string icon: "sports_esports"
    readonly property string empty: "No runs yet"
    // the header's action (an icon)
    readonly property string action: "play_arrow"

    readonly property int best: Store.appGet("dino", "highscore", 0)
    readonly property var runs: Store.appGet("dino", "runs", [])
    readonly property int count: best
    readonly property string countText: best > 0 ? `Best ${best}` : "Not played yet"

    // a clock for the ages
    property real now: Date.now()
    readonly property Timer clock: Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    readonly property var items: {
        let marked = false;
        return runs.map((r, i) => {
            const isBest = !marked && r.score === best;
            if (isBest)
                marked = true;
            return {
                key: String(r.time),
                lead: isBest ? "emoji_events" : "directions_run",
                image: "",
                title: String(r.score),
                sub: isBest ? "High score" : "",
                time: age(r.time),
                pinned: false
            };
        });
    }

    function age(t: real): string {
        const d = new Date(t);
        if (d.toDateString() === new Date(now).toDateString())
            return Qt.formatTime(d, "hh:mm");
        return Qt.locale().monthName(d.getMonth(), Locale.ShortFormat) + " " + d.getDate();
    }

    function opened() {
        now = Date.now();
    }
    function openApp() {
        Runtime.openApp("dino", {});
    }
    function activate(item: var) {
        openApp();
    }
    function run() {
        Runtime.openApp("dino", {
            play: true
        });
    }
}
