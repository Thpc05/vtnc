import QtQuick
import qs.kit as K

// Visualizer "shapes": one shape that morphs with the music (the workspaces shapes' sibling,
// K.M3Shape): the louder, the spikier (circle → cookie12 → cookie9 → sunny → softBurst), picked at
// most every 220 ms so each morph lands; it also breathes (scale with the energy) and turns slowly
// while it plays.
Item {
    id: root

    property var levels: []
    property color colour
    // the activation level (0…1, 2026-10-27, user, as the dots' threshold): below it the shape stays calm
    // (a circle at its smallest), above it the energy left drives it
    property real threshold: 0

    // the overall energy (0…1): the mean level, past the activation level
    readonly property real energy: {
        let s = 0;
        for (const v of levels)
            s += v;
        const mean = levels.length > 0 ? s / levels.length : 0;
        const t = Math.max(0, Math.min(0.95, threshold));
        return Math.max(0, (mean - t) / (1 - t));
    }
    readonly property var ladder: ["circle", "cookie12", "cookie9", "sunny", "softBurst"]

    Timer {
        interval: 220
        running: true
        repeat: true
        onTriggered: shape.shape = root.ladder[Math.min(root.ladder.length - 1, Math.floor(root.energy * 1.6 * root.ladder.length))]
    }

    K.M3Shape {
        id: shape
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        shape: "circle"
        color: root.colour
        scale: 0.6 + 0.4 * Math.min(1, root.energy * 1.6)
        Behavior on scale {
            NumberAnimation {
                duration: 90
            }
        }
        RotationAnimator on rotation {
            running: K.Kit.anim.enabled
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 12000
        }
    }
}
