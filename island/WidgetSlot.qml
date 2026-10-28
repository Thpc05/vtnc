import QtQuick
import Quickshell
import qs.core
import qs.theme
import qs.components
import qs.iwidgets
import qs.kit as K

// Hosts one Iwidget. Hidden widgets stay loaded but collapse to width 0,
// so showing/hiding them morphs smoothly with the island.
Item {
    id: root

    required property string widgetId
    property bool shown: true
    // the look to render (a style id from iwidgets/catalog.js); never "hidden" — hiding is `shown`
    property string style: WidgetRegistry.defaultStyle(widgetId, "compact")
    // direction of the island's change (growing or shrinking), the same for every slot in the row; widgets
    // may read it
    property bool growing: shown
    property ShellScreen screen: null
    // the island's mode (compact / expanded), for widgets with per-mode options
    property string mode: "compact"
    // horizontal padding on each side; collapses together with the widget
    property real gap: Tokens.spacing.s / 2
    // inside a section's card (island.anchors.<section>.card): the widget draws on the card's palette
    property bool inCard: false
    // whole pixels only while the island rests (K.Kit.snap)
    property bool snap: true

    readonly property Item widget: frame.widget

    // Final width (not animated). Widgets may declare `targetWidth` when their implicitWidth
    // animates internally; otherwise implicitWidth is used (the frame adds a card's padding).
    // Widgets with nothing to show (e.g. media without a player) report 0 and the slot collapses.
    readonly property real widgetWidth: frame.targetWidth
    // whole pixels (2026-10-27: a text's fractional width put the slots after it at half pixels)
    readonly property real targetWidth: shown && widgetWidth > 0 ? Math.ceil(widgetWidth + 2 * gap) : 0

    implicitWidth: targetWidth
    implicitHeight: frame.implicitHeight
    // only the width decides: the fade ends before the width does, and dropping a slot
    // that still has a few px would make the whole row jump
    visible: implicitWidth > 0.5
    opacity: shown ? 1 : 0
    clip: true

    // the island body's own curve (Island: K.Anim BodySpatial), so the content and the body move as one
    // (R1, 2026-10-11; was ContentAnim's OutBack / OutQuart)
    Behavior on implicitWidth {
        enabled: K.Kit.anim.enabled
        K.Anim {
            type: K.Anim.BodySpatial
        }
    }
    Behavior on opacity {
        enabled: K.Kit.anim.enabled
        K.Anim {
            type: K.Anim.FastEffects
        }
    }

    // Widgets with `fillsSlot: true` get the slot's animated width and lay themselves out
    // inside it; the others stay at their own width, centered (the clip trims the sides).
    readonly property bool fills: frame.fills

    IwidgetFrame {
        id: frame
        anchors.verticalCenter: parent.verticalCenter
        // x, not anchors switched by `fills` (with both set for a moment, Qt writes the width and the
        // binding breaks; the settings preview had it)
        x: root.fills ? root.gap : K.Kit.snap((root.width - width) / 2, root.snap)
        width: root.fills ? Math.max(0, root.width - 2 * root.gap) : implicitWidth
        fillWidth: width
        widgetId: root.widgetId
        style: root.style
        mode: root.mode
        growing: root.growing
        screen: root.screen
        inCard: root.inCard
    }
}
