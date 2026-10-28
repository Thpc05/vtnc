import QtQuick
import qs.kit as K

// The dashboard visualizer's Shapes (2026-10-27, user: "follow the rhythm"): one M3 shape that dances to
// the beat (Widget.qml detects it in the bass; the shape has its own, usually lower, trigger). Each beat:
//  - a pulse: the size punches up at once and eases back (`pulse` 1 → 0)
//  - (on the shape's trigger) the next shape, from the other family (round ↔ spiky), at most every
//    `shapeInterval`, morphing gently
//  - a small, smooth kick to its slow turn
// Between beats it breathes with the (auto-gained) energy. With no beat for a while (ambient, classical)
// it falls back to the energy alone: the spikier the louder, re-picked every 600 ms, as the island's.
Item {
    id: root

    // the energy, 0…1 (gained and past the activation level, Widget.qml)
    property real energy: 0
    property color colour
    // set by the beats (Widget.qml calls beat())
    property real pulse: 0
    // a beat came recently: shapes follow the beats, else the energy
    property bool beating: false
    property real lastShape: 0
    // the least time between two new shapes (options.morph: calm 0.6 s · normal 0.3 s · lively 0.15 s)
    property int shapeInterval: 300
    // the size's range (options.pulse, 2026-10-27, user): subtle · normal · strong; [rest, energy, beat]
    property string pulseSize: "normal"
    readonly property var sizes: pulseSize === "subtle" ? [0.76, 0.12, 0.08] : pulseSize === "strong" ? [0.5, 0.25, 0.25] : [0.62, 0.21, 0.17]

    // calm → spiky (the energy ladder), and the pool a beat picks from
    readonly property var ladder: ["circle", "cookie12", "cookie9", "sunny", "softBurst"]
    readonly property var soft: ["cookie4", "cookie6", "cookie7", "cookie9", "clover4"]
    readonly property var sharp: ["cookie12", "sunny", "softBurst", "clover8"]

    function pickOther(pool: var): string {
        const options = pool.filter(s => s !== shape.shape);
        return options[Math.floor(Math.random() * options.length)];
    }

    // a beat of `strength` (0…1: how far over the bass's average it jumped)
    function beat(strength: real) {
        pulse = Math.min(1, 0.55 + strength);
        pulseFall.restart();
        kick.from = shape.turn;
        kick.to = shape.turn + 6 + 6 * strength;
        kick.restart();
        calm.restart();
        beating = true;
    }

    // a bass jump past the shape's own trigger (Widget.qml): a new shape at most every `shapeInterval` (user:
    // on every beat it was abrupt), always from the other family (round ↔ spiky), so each change shows
    function changeShape() {
        const now = Date.now();
        if (now - lastShape <= shapeInterval)
            return;
        lastShape = now;
        shape.shape = pickOther(soft.includes(shape.shape) || shape.shape === "circle" ? sharp : soft);
        calm.restart();
        beating = true;
    }

    NumberAnimation {
        id: pulseFall
        target: root
        property: "pulse"
        to: 0
        duration: 380
        easing.type: Easing.OutCubic
    }
    // no beat for 2.5 s: back to the energy
    Timer {
        id: calm
        interval: 2500
        onTriggered: root.beating = false
    }
    Timer {
        interval: 600
        running: !root.beating
        repeat: true
        onTriggered: shape.shape = root.ladder[Math.min(root.ladder.length - 1, Math.floor(root.energy * 1.6 * root.ladder.length))]
    }

    // the slow turn and the beats' kicks
    NumberAnimation {
        id: kick
        target: shape
        property: "turn"
        duration: 600
        easing.type: Easing.InOutSine
    }
    Timer {
        interval: 50
        running: K.Kit.anim.enabled && !kick.running
        repeat: true
        onTriggered: shape.turn = (shape.turn + 1.2) % 360
    }

    K.M3Shape {
        id: shape
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        shape: "circle"
        gentle: true
        color: root.colour
        // breathing with the energy, plus the beat's punch (user: near the first jump, 0.58 + 0.24 energy +
        // 0.2 pulse; what felt abrupt was the morph, now gentle)
        scale: Math.min(1, root.sizes[0] + root.sizes[1] * root.energy + root.sizes[2] * root.pulse)
    }
}
