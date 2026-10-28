import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.kit as K
import qs.dwidgets

// A Qwidget's mark (2026-10-11), one drawing for the island's Quick configs and the dashboard's (and
// the toggles), in the Iwidget family:
//  - shapes: off a rounded square (pal.off), on an accent circle (morphing; tighter while pressed). With
//    Random shapes (`shapesRandom`, the Dwidget's options.randomShapes; 2026-10-16, user): off a circle, on an accent M3 shape, the
//    same for every mark as the dashboard opens and a new one when it turns on, connects or disconnects
//    (its symbol changes); a rounded square while pressed
//  - tones: off a bare icon in a weak tone, on a rounded square in the tone
//  - tone: no fill ever: the icon in the tone, on = filled and heavier
// An armed session action (q.danger) takes the error colour. `weight` 300…1500: Material Symbols'
// wght ends at 700, past it the glyph is emboldened by hand (copies around it, up to 1.2 px at 1500).
// An app's image icon (q.image) replaces the symbol. Even sizes, whole positions (icon alignment).
Item {
    id: root

    property QtObject q: null
    property string look: "shapes"
    property var pal: K.Kit.bare
    property color tone: pal.accent
    property color overTone: pal.overAccent
    property int iconSize: 14
    property int weight: 400
    property bool pressed: false

    readonly property bool on: q?.active ?? false
    readonly property bool danger: q?.danger ?? false
    readonly property color accent: danger ? Colors.error : look === "shapes" ? pal.accent : tone
    readonly property color overAccent: danger ? Colors.overError : look === "shapes" ? pal.overAccent : overTone
    readonly property real embolden: Math.max(0, Math.min(1, ((on && look === "tone" ? Math.max(weight, 700) : weight) - 700) / 800)) * 1.2
    // Shapes with Random shapes on: M3 shapes instead of the rounded square / circle
    readonly property bool randomShapes: look === "shapes" && random.enabled
    // the hover / ripple follow the shape (random shapes: round, as their outline about)
    readonly property real shapeRadius: randomShapes ? width / 2 : fill.radius

    // the "on" shape, re-picked on each event
    // the Dwidget's Random shapes option
    property bool shapesRandom: true
    readonly property RandomShape random: RandomShape {
        enabled: root.shapesRandom
    }
    readonly property string symbol: q?.symbol ?? ""
    onOnChanged: if (randomShapes && on)
        random.next()
    onSymbolChanged: if (randomShapes && on)
        random.next()

    implicitWidth: 22
    implicitHeight: 22
    opacity: q?.available ?? true ? 1 : 0.38

    K.M3Shape {
        anchors.fill: parent
        visible: root.randomShapes
        samples: 48
        animate: !root.random.instant
        shape: root.pressed ? "square" : root.on || root.danger ? root.random.shape : "circle"
        color: root.on || root.danger ? root.accent : root.pal.off
        Behavior on color {
            K.CAnim {}
        }
    }
    Rectangle {
        id: fill
        anchors.fill: parent
        visible: !root.randomShapes
        radius: root.look === "shapes" ? (root.pressed ? width * 0.18 : root.on || root.danger ? width / 2 : width * 0.3) : Math.round(width * 0.3)
        color: root.look === "tone" ? "transparent" : root.on || root.danger ? root.accent : root.look === "shapes" ? root.pal.off : Qt.alpha(root.accent, 0)
        Behavior on radius {
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
        Behavior on color {
            K.CAnim {}
        }
    }

    readonly property color ink: root.look === "tone" ? (root.danger ? Colors.error : root.on ? root.tone : Qt.alpha(root.tone, 0.7)) : root.on || root.danger ? root.overAccent : root.look === "shapes" ? root.pal.over : Qt.alpha(root.accent, 0.55)

    IconImage {
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        implicitSize: root.iconSize + 2
        visible: (root.q?.image ?? "") !== ""
        source: root.q?.image ?? ""
        asynchronous: true
    }
    // past 700: copies around the glyph thicken it (see `embolden`)
    Repeater {
        model: root.embolden > 0 && (root.q?.image ?? "") === "" ? [[-1, 0], [1, 0], [0, -1], [0, 1]] : []
        K.MaterialIcon {
            required property var modelData
            x: glyph.x + modelData[0] * root.embolden
            y: glyph.y + modelData[1] * root.embolden
            text: glyph.text
            size: glyph.size
            fill: glyph.fill
            weight: 700
            color: glyph.color
        }
    }
    K.MaterialIcon {
        id: glyph
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        visible: (root.q?.image ?? "") === ""
        text: root.q?.symbol ?? ""
        size: root.iconSize
        fill: root.on ? 1 : 0
        weight: Math.min(700, root.look === "tone" && root.on ? Math.max(root.weight, 600) : root.weight)
        color: root.ink
        style: root.embolden > 0 ? Text.Outline : Text.Normal
        styleColor: color
    }
}
