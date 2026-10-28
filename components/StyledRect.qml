pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.kit as K

// A flat M3 surface by `variant`, on the shell's surface ladder (Kit.expressive: page → container →
// off → high → on; OLED-aware). `item` is the content color that reads on it. Clips its children.
//   bg / barbg        the page (Colors.background)        transparent   nothing
//   pane / common     container (cards, panes)            internalbg    off (fields, controls)
//   focus             high (hover, a control on a control) popup         container + an outline
//   primary / secondary / tertiary / error                the accent's filled container
//   …focus            the same, a step brighter           over…         the accent's content color
// vtnc: was compat/Styling's ambxst variants (gradients, halftone); the shell is flat now.
ClippingRectangle {
    id: root

    required property string variant

    property bool enableShadow: false
    property bool enableBorder: true
    property bool animateRadius: true
    property real backgroundOpacity: -1  // -1: opaque

    readonly property var ladder: K.Kit.expressive
    // [fill, content, border color, border width]
    readonly property var look: {
        // (the Kit singleton goes away first while the shell reloads)
        if (!ladder)
            return ["transparent", "transparent", "transparent", 0];
        switch (variant) {
        case "transparent":
            return ["transparent", Colors.overSurface, "transparent", 0];
        case "bg":
        case "barbg":
            return [ladder.page, Colors.overBackground, "transparent", 0];
        case "internalbg":
            return [ladder.off, Colors.overSurface, "transparent", 0];
        case "popup":
            return [ladder.container, Colors.overSurface, Colors.outlineVariant, 1];
        case "focus":
            return [ladder.high, Colors.overSurface, "transparent", 0];
        case "primary":
            return [Colors.primary, Colors.overPrimary, "transparent", 0];
        case "primaryfocus":
            return [Qt.lighter(Colors.primary, 1.12), Colors.overPrimary, "transparent", 0];
        case "overprimary":
            return [Colors.overPrimary, Colors.primary, "transparent", 0];
        case "secondary":
            return [Colors.secondaryContainer, Colors.overSecondaryContainer, "transparent", 0];
        case "secondaryfocus":
            return [Qt.lighter(Colors.secondaryContainer, 1.12), Colors.overSecondaryContainer, "transparent", 0];
        case "oversecondary":
            return [Colors.overSecondaryContainer, Colors.secondaryContainer, "transparent", 0];
        case "tertiary":
            return [Colors.tertiaryContainer, Colors.overTertiaryContainer, "transparent", 0];
        case "tertiaryfocus":
            return [Qt.lighter(Colors.tertiaryContainer, 1.12), Colors.overTertiaryContainer, "transparent", 0];
        case "overtertiary":
            return [Colors.overTertiaryContainer, Colors.tertiaryContainer, "transparent", 0];
        case "error":
            return [Colors.errorContainer, Colors.overErrorContainer, "transparent", 0];
        case "errorfocus":
            return [Qt.lighter(Colors.errorContainer, 1.12), Colors.overErrorContainer, "transparent", 0];
        case "overerror":
            return [Colors.overErrorContainer, Colors.errorContainer, "transparent", 0];
        default:
            // pane, common
            return [ladder.container, Colors.overSurface, "transparent", 0];
        }
    }

    property color item: look[1]

    clip: true
    antialiasing: true
    contentUnderBorder: true
    radius: variant === "transparent" ? 0 : Tokens.radius(0)
    color: backgroundOpacity >= 0 ? Qt.alpha(look[0], Qt.color(look[0]).a * backgroundOpacity) : look[0]

    Behavior on radius {
        enabled: root.animateRadius
        K.Anim {
            type: K.Anim.FastSpatial
        }
    }
    Behavior on color {
        K.CAnim {}
    }

    layer.enabled: enableShadow
    layer.effect: Shadow {}

    // the border on top (ClippingRectangle artifacts otherwise)
    Rectangle {
        anchors.fill: parent
        visible: root.enableBorder && root.look[3] > 0
        radius: root.radius
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        color: "transparent"
        border.color: root.look[2]
        border.width: root.look[3]
    }
}
