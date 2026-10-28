import QtQuick
import qs.components
import qs.theme
import qs.kit as K

// The clock's and the date's text, each styled from its own options block (island.clock /
// island.date, Island → Layout): font, weight, size, letter spacing, roundness (the font's ROND axis:
// Google Sans Flex), colour (a role) and an optional background (container / tonal / primary) with its
// own rounding (-1 = a pill). "default" colour = the text colour of the background under it.
Item {
    id: root

    property var options: ({})
    // the palette under it (the island card's, or the bare island's: IwidgetFrame)
    property var pal: K.Kit.bare
    property string text
    // the widget's own defaults (an empty font, a 0 weight)
    property string defaultFamily: K.Kit.clockFamily
    property int defaultWeight: Font.DemiBold

    readonly property string background: options.background || "none"
    readonly property bool hasBackground: background !== "none"
    readonly property color fill: background === "primary" ? Colors.primary : background === "tonal" ? Colors.secondaryContainer : K.Kit.expressive.off
    readonly property color baseInk: background === "primary" ? Colors.overPrimary : background === "tonal" ? Colors.overSecondaryContainer : hasBackground ? Colors.overSurface : pal.over
    readonly property color ink: {
        switch (options.color) {
        case "primary":
            return hasBackground ? Colors.primary : pal.accent;
        case "secondary":
            return Colors.secondary;
        case "tertiary":
            return Colors.tertiary;
        case "variant":
            return hasBackground ? Qt.alpha(baseInk, 0.75) : pal.overVariant;
        default:
            return baseInk;
        }
    }
    readonly property real padX: hasBackground ? K.Kit.padding.small : 0
    readonly property real padY: hasBackground ? 3 : 0

    implicitWidth: Math.ceil(label.implicitWidth) + 2 * padX
    implicitHeight: Math.ceil(label.implicitHeight) + 2 * padY

    Rectangle {
        anchors.fill: parent
        visible: root.hasBackground
        radius: (root.options.rounding ?? -1) < 0 ? height / 2 : Math.min(root.options.rounding, height / 2)
        color: root.fill
        Behavior on color {
            K.CAnim {}
        }
    }

    // the line box keeps room for descenders the digits never use, so centring the box left the time
    // ~1.5 px high (user): centre the caps / digits instead (descenders still hang below, as they should)
    TextMetrics {
        id: caps
        font: label.font
        text: "H0"
    }
    FontMetrics {
        id: metrics
        font: label.font
    }

    StyledText {
        id: label
        x: Math.round((parent.width - implicitWidth) / 2)
        y: Math.round((parent.height - caps.tightBoundingRect.height) / 2 - (metrics.ascent + caps.tightBoundingRect.y))
        text: root.text
        font.family: root.options.font || root.defaultFamily
        font.pixelSize: (root.options.size ?? 0) > 0 ? root.options.size : Tokens.font.normal
        font.weight: root.options.weight || root.defaultWeight
        font.letterSpacing: root.options.letterSpacing ?? 0
        font.variableAxes: ({
                "ROND": root.options.roundness ?? 25
            })
        color: root.ink
        Behavior on color {
            K.CAnim {}
        }
    }
}
