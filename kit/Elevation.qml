import QtQuick
import QtQuick.Effects
import qs.theme

// An M3 elevation shadow (caelestia's Elevation, ported): `level` 0…5 → dp 0, 1, 3, 6, 8, 12.
// Put it under the surface it lifts, with the same size and radius.
RectangularShadow {
    property int level
    property real dp: [0, 1, 3, 6, 8, 12][Math.max(0, Math.min(5, level))]

    color: Qt.alpha(Colors.shadow, 0.7)
    blur: (dp * 5) ** 0.7
    spread: -dp * 0.3 + (dp * 0.1) ** 2
    offset.y: dp / 2

    Behavior on dp {
        Anim {
            type: Anim.SlowEffects
        }
    }
}
