import QtQuick
import qs.core
import qs.services
import qs.theme
import qs.kit as K

// A music visualizer (2026-10-09, user), from services/Cava.qml. Styles, each drawing `levels` (N
// values 0…1) in one colour:
//  - bars: rounded bars mirrored around the middle
//  - dots: small dots, on or off with their level
//  - shapes: one shape morphing with the music (circle → spiky as it gets louder)
// (wave and blob were dropped, user.) Each also comes on the island card (Card variants: `pal`). It
// collapses to 0 while nothing plays, and cava runs only while it's shown and playing (island.visualizer
// .source "random": a made-up rhythm instead, no cava); both wait a
// few seconds before stopping, so a blip (switching apps hides the island or flickers the player for
// a moment) doesn't restart it (user). With island.visualizer.alwaysShow (2026-10-15, user) it never
// collapses: flat at its min height while nothing plays (cava still runs only while playing). Options (Island → Layout → Visualizer):
// island.visualizer.color (as the tray's tint) and per island mode { bars, width (0 = auto), max / min
// height (bars) }.
Item {
    id: root

    property string style: "bars"
    // from the frame: the island mode and the palette (the island card's, or the bare island's)
    property string mode: "compact"
    property var pal: K.Kit.bare

    readonly property var options: Store.island.visualizer?.[mode] ?? ({})
    readonly property int count: Math.max(4, Math.min(48, options.bars ?? 16))
    // playing, held through short blips: it turns off (collapses) only after island.visualizer.hideDelay
    // seconds without playing (1 by default; user: quicker); the bars fall flat at once, and it fades out
    // as it collapses
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
        interval: Math.max(0, Store.island.visualizer?.hideDelay ?? 1) * 1000
        onTriggered: root.playing = MprisController.isPlaying
    }

    // the colour (primary / surface / variant / secondary / tertiary)
    readonly property string colorRole: Store.island.visualizer?.color || "primary"
    readonly property color colour: {
        switch (colorRole) {
        case "surface":
            return pal.over;
        case "variant":
            return pal.overVariant;
        case "secondary":
            return Colors.secondary;
        case "tertiary":
            return Colors.tertiary;
        default:
            return pal.accent;
        }
    }

    // what drives it: "music" (cava) or "random" (a made-up rhythm, only while something plays; no
    // cava then)
    readonly property bool random: Store.island.visualizer?.source === "random"

    // the target levels: cava's own `count` bands (a cava per bar count, services/Cava.qml), or the random
    // rhythm's
    function targets(): var {
        // the music stopped: fall flat at once (not frozen until it collapses)
        if (!MprisController.isPlaying)
            return Array(count).fill(0);
        if (random) {
            const out = [];
            for (let i = 0; i < count; i++)
                out.push(rhythm[i] ?? 0);
            return out;
        }
        return Cava.valuesFor(count);
    }

    // the levels drawn, smoothed toward the targets each frame (a quick rise, a slower fall): cava's
    // raw frames are noisy, and easing the drawn heights instead fought their pixel rounding (the bars
    // trembled, user)
    property var levels: []
    // what's drawn: always `count` levels, flat before anything played and once it stopped (alwaysShow keeps
    // it on screen then)
    readonly property var drawnLevels: levels.length === count ? levels : Array(count).fill(0)
    onPlayingChanged: if (!playing)
        levels = []
    Timer {
        interval: 16
        running: root.playing && root.visible
        repeat: true
        onTriggered: {
            const t = root.targets();
            const out = [];
            for (let i = 0; i < t.length; i++) {
                const cur = root.levels[i] ?? 0;
                out.push(cur + (t[i] - cur) * (root.random ? (t[i] > cur ? 0.14 : 0.07) : (t[i] > cur ? 0.45 : 0.18)));
            }
            root.levels = out;
        }
    }

    // random: new targets every 320 ms (slow, user), a shared beat envelope times a per-bar jitter; the
    // levels glide to them gently (the smoothing above)
    property var rhythm: []
    property real beat: 0
    Timer {
        interval: 320
        running: root.random && root.playing && root.visible
        repeat: true
        onTriggered: {
            root.beat = (root.beat + 1) % 4;
            const pulse = root.beat === 0 ? 1 : root.beat === 2 ? 0.75 : 0.45;
            const out = [];
            for (let i = 0; i < root.count; i++)
                out.push(Math.min(1, pulse * (0.25 + 0.75 * Math.random())));
            root.rhythm = out;
        }
    }

    // the width each style needs per level when `width` is auto
    readonly property real pitch: style === "dots" ? 7 : 5
    readonly property real fixedWidth: options.width ?? 0
    // shown: playing, or always (alwaysShow)
    readonly property bool shown: playing || (Store.island.visualizer?.alwaysShow ?? false)
    implicitWidth: shown ? (fixedWidth > 0 ? fixedWidth : style === "shapes" ? 20 : count * pitch) : 0
    // bars: their max height (the mode's maxHeight, 20 by default) and min height (minHeight, what a
    // silent bar keeps; 2 by default, 0 = it vanishes; never above the max)
    readonly property int maxHeight: 2 * Math.round(Math.max(6, Math.min(28, options.maxHeight ?? 20)) / 2)
    readonly property int minHeight: Math.min(maxHeight, 2 * Math.round(Math.max(0, Math.min(28, options.minHeight ?? 2)) / 2))
    opacity: shown ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
    implicitHeight: style === "bars" ? Math.max(20, maxHeight) : 20

    // cava only while shown (the slot's width is >0) and playing, for both island modes' bar counts (one
    // cava each, one when they match), so switching modes is instant. New counts are taken at once, the
    // ones no longer wanted let go after 3 s (the island hides for a moment when switching apps; a count
    // changed in settings: the new one runs before the old stops, so it never goes flat)
    readonly property bool holding: playing && visible && !random
    readonly property var wanted: {
        if (!holding)
            return [];
        const c = Store.island.visualizer?.compact?.bars ?? 16;
        const e = Store.island.visualizer?.expanded?.bars ?? 16;
        return c === e ? [c] : [c, e];
    }
    // the counts this instance holds
    property var held: []
    function sync() {
        const add = wanted.filter(n => !held.includes(n));
        for (const n of add)
            Cava.acquire(n);
        if (add.length > 0)
            held = held.concat(add);
        if (held.some(n => !wanted.includes(n)))
            releaseDelay.restart();
        else
            releaseDelay.stop();
    }
    Timer {
        id: releaseDelay
        interval: 3000
        onTriggered: {
            const keep = [];
            for (const n of root.held) {
                if (root.wanted.includes(n))
                    keep.push(n);
                else
                    Cava.release(n);
            }
            root.held = keep;
        }
    }
    onWantedChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: {
        for (const n of held)
            Cava.release(n);
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.style === "dots" ? dots : root.style === "shapes" ? shapes : bars
    }
    Component {
        id: bars
        BarsView {
            maxHeight: root.maxHeight
            minHeight: root.minHeight
            levels: root.drawnLevels
            colour: root.colour
        }
    }
    Component {
        id: dots
        DotsView {
            levels: root.drawnLevels
            colour: root.colour
            threshold: Math.max(0, Math.min(100, Store.island.visualizer?.dotThreshold ?? 33)) / 100
        }
    }
    Component {
        id: shapes
        ShapesView {
            levels: root.drawnLevels
            colour: root.colour
            threshold: Math.max(0, Math.min(95, Store.island.visualizer?.shapeThreshold ?? 0)) / 100
        }
    }
}
