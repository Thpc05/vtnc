import QtQuick
import qs.services
import qs.dwidgets
import qs.dwidgets.quick
import qs.kit as K
import "../catalog.js" as DCatalog

// The music visualizer (2026-10-27, user; a "single" Dwidget), from services/Cava.qml as the island's
// (iwidgets/visualizer): its styles at dashboard scale, each also on the card:
//  - bars: rounded bars mirrored around the middle, as wide as the room allows
//  - dots: a column of dots per band, lit up to its level
//  - shapes: one shape dancing to the beat (BeatShape, 2026-10-27): a punch, a new shape and a kick to its
//    turn on each beat detected in the bass, breathing with the energy between; the energy is auto-gained
//    (over the music's recent peak) so quiet songs move it too
// cava runs only while something plays and the dashboard shows it (one cava per bar count, shared with
// the island's when the counts match); the levels are smoothed each frame (a quick rise, a slower fall),
// and the music stopping holds a second before it lets go (a blip doesn't restart it). Options: color
// (the tones' role), bars (4…48), alwaysShow (flat while nothing plays; off: it fades out), threshold (the
// activation level: Shapes start moving, Dots light past it), and for Shapes sensitivity (how big a bass jump
// is a beat: low · medium · high) and morph (how often the shape may change: calm · normal · lively). Cava keeps running with the dashboard
// closed while music plays (VisualizerKeeper), so an open doesn't wait for it.
Dwidget {
    id: root

    readonly property bool card: DCatalog.isCard("visualizer", root.style)
    readonly property string look: DCatalog.baseStyle("visualizer", root.style)
    readonly property int count: Math.max(4, Math.min(48, root.options?.bars ?? 16))
    readonly property bool alwaysShow: root.options?.alwaysShow ?? true
    // the activation level (options.threshold %, 2026-10-27, user): Shapes start moving at it, Dots light
    // past it (each dot's own step on top)
    readonly property real threshold: Math.max(0, Math.min(90, root.options?.threshold ?? 0)) / 100

    DwidgetCard {
        id: cardHost
        anchors.fill: parent
        card: root.card
    }
    ToneColors {
        id: colors
        pal: cardHost.pal
        role: root.options?.color || "primary"
    }

    // playing, held a second through blips
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
        interval: 1000
        onTriggered: root.playing = MprisController.isPlaying
    }

    // cava for this count while it plays and shows (the dashboard open)
    readonly property bool holding: playing && root.visible
    property int held: 0
    function sync() {
        const want = holding ? count : 0;
        if (want === held)
            return;
        if (want > 0)
            Cava.acquire(want);
        if (held > 0)
            Cava.release(held);
        held = want;
    }
    onHoldingChanged: sync()
    onCountChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (held > 0)
        Cava.release(held)

    // the auto gain (2026-10-27, user): the levels over the music's recent peak, so a quiet song moves as
    // much as a loud one. The peak follows a louder moment at once and lets go slowly (~halves in 4 s)
    property real peak: 0.3
    readonly property real gain: Math.min(4, 1 / Math.max(0.08, peak))
    // the beat (in the bass: the lowest ~15 % of the bands): it jumps over its recent average (~0.4 s), past
    // a floor, at most one per 150 ms. Shapes dance to it (BeatShape)
    property real bassAverage: 0
    // options.sensitivity: how far the bass must jump over its average (low 1.6× · medium 1.35× · high 1.2×)
    // and the floor it must pass
    readonly property string sensitivity: root.options?.sensitivity || "medium"
    readonly property real beatJump: sensitivity === "low" ? 1.6 : sensitivity === "high" ? 1.2 : 1.35
    readonly property real beatFloor: sensitivity === "low" ? 0.32 : sensitivity === "high" ? 0.18 : 0.25
    property real lastBeat: 0
    signal beat(real strength)
    // the shape's own trigger (options.shapeTrigger %, 2026-10-27, user): the bass jump over its average that
    // changes the shape, apart from the beat's pulse (lower: more changes); 35 % = the beat's medium
    readonly property real shapeJump: 1 + Math.max(5, Math.min(100, root.options?.shapeTrigger ?? 35)) / 100
    property real lastShapeHit: 0
    signal shapeHit(real strength)

    // the levels drawn, smoothed toward cava's each frame
    property var levels: []
    readonly property var drawnLevels: levels.length === count ? levels : Array(count).fill(0)
    onPlayingChanged: if (!playing)
        levels = []
    Timer {
        interval: 16
        running: root.holding
        repeat: true
        onTriggered: {
            const t = MprisController.isPlaying ? Cava.valuesFor(root.count) : Array(root.count).fill(0);
            // the gain's peak and the beat, on the raw frame
            let sum = 0;
            for (const v of t)
                sum += v;
            const mean = t.length > 0 ? sum / t.length : 0;
            root.peak = Math.max(mean, root.peak * 0.997, 0.05);
            const lows = Math.max(1, Math.round(t.length * 0.15));
            let bass = 0;
            for (let i = 0; i < lows; i++)
                bass += t[i];
            bass = Math.min(1, bass / lows * root.gain);
            const now = Date.now();
            const strength = Math.min(1, (bass - root.bassAverage) / Math.max(0.1, root.bassAverage));
            if (bass > root.beatFloor && bass > root.bassAverage * root.beatJump && now - root.lastBeat > 150) {
                root.lastBeat = now;
                root.beat(strength);
            }
            if (bass > root.beatFloor * 0.6 && bass > root.bassAverage * root.shapeJump && now - root.lastShapeHit > 150) {
                root.lastShapeHit = now;
                root.shapeHit(strength);
            }
            root.bassAverage += (bass - root.bassAverage) * 0.04;
            const out = [];
            for (let i = 0; i < t.length; i++) {
                const cur = root.levels[i] ?? 0;
                out.push(cur + (t[i] - cur) * (t[i] > cur ? 0.45 : 0.18));
            }
            root.levels = out;
        }
    }

    Item {
        id: area
        anchors.fill: parent
        anchors.margins: cardHost.pad + Math.round(Math.min(root.width, root.height) * 0.08)
        opacity: root.playing || root.alwaysShow ? 1 : 0
        Behavior on opacity {
            K.Anim {
                type: K.Anim.DefaultEffects
            }
        }

        // the band's pitch, and a bar or dot about half of it (even, at least 2 px)
        readonly property real pitch: width / root.count
        readonly property int thick: Math.max(2, 2 * Math.round(Math.min(pitch * 0.55, 16) / 2))

        // bars
        Repeater {
            model: root.look === "bars" ? root.count : 0

            Rectangle {
                required property int index
                readonly property real level: root.drawnLevels[index] ?? 0
                x: Math.round((index + 0.5) * area.pitch - width / 2)
                y: Math.round((area.height - height) / 2)
                width: area.thick
                height: area.thick + 2 * Math.round(level * (area.height - area.thick) / 2)
                radius: width / 2
                color: colors.tone
            }
        }

        // dots: a column per band, lit from the middle out (mirrored, as the bars)
        Repeater {
            model: root.look === "dots" ? root.count : 0

            Column {
                id: dotColumn
                required property int index
                readonly property real level: root.drawnLevels[index] ?? 0
                readonly property int rows: Math.max(1, Math.floor((area.height + spacing) / (area.thick + spacing)))
                x: Math.round((index + 0.5) * area.pitch - area.thick / 2)
                y: Math.round((area.height - implicitHeight) / 2)
                spacing: Math.max(2, Math.round(area.thick / 2))

                Repeater {
                    model: dotColumn.rows

                    Rectangle {
                        required property int index
                        // the distance from the middle row, 0…1
                        readonly property real away: dotColumn.rows > 1 ? Math.abs(index - (dotColumn.rows - 1) / 2) / ((dotColumn.rows - 1) / 2) : 0
                        width: area.thick
                        height: area.thick
                        radius: width / 2
                        // past the activation level, the level left lights the column from the middle
                        readonly property real lit: Math.max(0, (dotColumn.level - root.threshold) / (1 - root.threshold))
                        color: away <= lit + 0.001 && (lit > 0 || away === 0) ? colors.tone : Qt.alpha(colors.tone, 0.18)
                    }
                }
            }
        }

        BeatShape {
            id: beatShape
            anchors.fill: parent
            visible: root.look === "shapes"
            colour: colors.tone
            pulseSize: root.options?.pulse || "normal"
            // (user: normal 0.3 s, lively 0.15 s; calm keeps the halving, 0.6 s)
            shapeInterval: root.options?.morph === "calm" ? 600 : root.options?.morph === "lively" ? 150 : 300
            // the mean level, gained, past the activation level
            energy: {
                let s = 0;
                for (const v of root.drawnLevels)
                    s += v;
                const mean = Math.min(1, (root.drawnLevels.length > 0 ? s / root.drawnLevels.length : 0) * root.gain);
                return Math.max(0, (mean - root.threshold) / (1 - root.threshold));
            }
            Connections {
                target: root
                enabled: root.look === "shapes"
                function onBeat(strength) {
                    beatShape.beat(strength);
                }
                function onShapeHit(strength) {
                    beatShape.changeShape();
                }
            }
        }
    }
}
