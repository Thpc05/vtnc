import QtQuick
import qs.dwidgets
import qs.kit as K

// A summary's mark (2026-10-17), the Iwidget family's "on" mark: Shapes an accent M3 shape (with Random
// shapes the dashboard's random one, else a circle), Two tones a rounded square in the tone, Tone the
// bare icon in the tone. Even sizes, whole positions.
Item {
    id: root

    property string look: "shapes"
    property var pal: K.Kit.bare
    property color tone: pal.accent
    property color overTone: pal.overAccent
    property string icon
    property bool randomShapes: true

    readonly property RandomShape random: RandomShape {
        enabled: root.randomShapes
    }

    K.M3Shape {
        anchors.fill: parent
        visible: root.look === "shapes"
        shape: root.randomShapes && root.random.shape !== "" ? root.random.shape : "circle"
        animate: !root.random.instant
        color: root.pal.accent
    }
    Rectangle {
        anchors.fill: parent
        visible: root.look === "tones"
        radius: Math.round(width * 0.3)
        color: root.tone
    }
    K.MaterialIcon {
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        text: root.icon
        size: 2 * Math.round(root.width * (root.look === "tone" ? 0.32 : 0.24))
        fill: 1
        color: root.look === "tone" ? root.tone : root.look === "tones" ? root.overTone : root.pal.overAccent
    }
}
