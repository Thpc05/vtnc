import QtQuick
import Quickshell
import qs.core
import qs.theme
import qs.kit as K

// Idle content of the island: three sections (left / center / right).
// Widget section "off" → not created. Per mode (compact / expanded) each widget has a style
// (iwidgets/catalog.js) or "hidden" (collapses to width 0 in that mode).
// island.anchors.<mode> (Island → Anchors, 2026-10-11; per island mode since 2026-10-15):
//  - anchorCenter on: the center section is kept truly centered, so the width reserves max(left, right)
//    on both sides. Off: the sections are packed (left | center | right) and the center floats in the
//    middle of whatever space is left between the other two
//  - the gap between the widgets of a section and between the sections, and a card behind each section
//    (left / center / right: the island card, its widgets on the card's palette).
Item {
    id: root

    property bool expanded: false
    readonly property string mode: expanded ? "expanded" : "compact"
    // ids of widgets hidden in compact but shown for a moment (media flash)
    property var flashed: []
    property ShellScreen screen: null
    // sections spread at least this wide (the island's min width minus padding);
    // minWidth may animate, finalMinWidth is where it's going (for targetWidth)
    property real minWidth: 0
    property real finalMinWidth: minWidth
    // whole pixels only while the island rests (K.Kit.snap, 2026-10-28): rounded while it moved, the centre section
    // and the slots' widgets flipped a pixel back and forth through the body's overshoot
    property bool snap: true

    readonly property var widgets: (Store.island.widgets ?? []).filter(w => w.section !== "off" && WidgetRegistry.has(w.id))

    function sectionWidgets(section: string): var {
        return widgets.filter(w => w.section === section);
    }

    // this mode's anchors
    readonly property var anchorOptions: Store.island.anchors?.[mode] ?? ({})
    readonly property bool anchorCenter: anchorOptions.anchorCenter ?? false
    readonly property real gap: anchorOptions.between ?? Tokens.spacing.s
    // between the widgets of a section (each slot pads half of it on both sides)
    readonly property real innerGap: anchorOptions.gap ?? Tokens.spacing.s

    // Gaps between sections shrink with the sections (never on/off in one frame, which made
    // the row jump by gap/2 when a section reached 0).
    function gapBetween(a: real, b: real): real {
        return Math.max(0, Math.min(gap, a, b));
    }

    // width of the packed layout (anchorCenter off)
    function packedWidth(l: real, c: real, r: real): real {
        const gapLR = Math.max(0, gapBetween(l, r) - c);
        return l + c + r + gapBetween(l, c) + gapBetween(r, c) + gapLR;
    }

    function layoutWidth(l: real, c: real, r: real, min: real): real {
        if (!anchorCenter)
            return Math.max(min, packedWidth(l, c, r));
        const side = Math.max(l, r);
        return Math.max(min, c + 2 * (side + gapBetween(c, side)));
    }

    // final width, used by the island as its morph target (animating widths would
    // restart the island's animation every frame)
    readonly property real targetWidth: layoutWidth(left.targetWidth, center.targetWidth, right.targetWidth, finalMinWidth)

    // current (animated) width
    implicitWidth: layoutWidth(left.implicitWidth, center.implicitWidth, right.implicitWidth, minWidth)
    implicitHeight: Math.max(left.implicitHeight, center.implicitHeight, right.implicitHeight)

    // a section: its widgets in a row, on the island card when island.anchors.<mode>.<name>.card; the card's
    // padding shrinks with the row, so an empty section still collapses to 0
    component Section: Item {
        id: section
        property string name
        readonly property bool card: root.anchorOptions?.[name]?.card ?? false
        // the card's inset beyond the slots' own half gaps
        readonly property real pad: card ? Math.max(0, K.Kit.padding.small - root.innerGap / 2) : 0
        function padded(w: real): real {
            return w + 2 * Math.min(pad, w / 2);
        }
        readonly property real targetWidth: {
            let w = 0;
            for (const c of row.children)
                if (c.targetWidth !== undefined)
                    w += c.targetWidth;
            return padded(w);
        }
        implicitWidth: padded(row.implicitWidth)
        implicitHeight: card && row.implicitWidth > 0.5 ? Math.max(26, row.implicitHeight + 4) : row.implicitHeight
        height: implicitHeight
        anchors.verticalCenter: parent.verticalCenter

        // fades with the widgets when the section is going to 0 (shrinking with them, it lagged the
        // island's body and showed as half pills outside it)
        Rectangle {
            anchors.fill: parent
            opacity: section.card && section.targetWidth > 0.5 ? 1 : 0
            visible: opacity > 0 && section.width > 0.5
            radius: height / 2
            color: K.Kit.islandCard.fill
            Behavior on color {
                K.CAnim {}
            }
            Behavior on opacity {
                K.Anim {
                    type: K.Anim.FastEffects
                }
            }
        }

        Row {
            id: row
            x: Math.min(section.pad, width / 2)
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: root.sectionWidgets(section.name)

                WidgetSlot {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    widgetId: modelData.id
                    id: slot
                    gap: root.innerGap / 2
                    inCard: section.card
                    snap: root.snap
                    readonly property bool isFlashed: root.flashed.includes(modelData.id)
                    // the style chosen for the current mode ("hidden" = not in this mode); a flashed
                    // widget that is hidden in compact shows its factory compact look for a moment
                    readonly property string wanted: {
                        const w = modelData[root.mode];
                        if (isFlashed && w === WidgetRegistry.hidden)
                            return WidgetRegistry.defaultStyle(modelData.id, "compact");
                        return w;
                    }
                    // while fading out to hidden it keeps the last look it had (it never switches
                    // layout on its way out)
                    // (plain value, not a binding: a binding would re-evaluate on the way to hidden)
                    property string lastVisible: ""
                    Component.onCompleted: lastVisible = wanted !== WidgetRegistry.hidden ? wanted : WidgetRegistry.defaultStyle(modelData.id, "compact")
                    onWantedChanged: if (wanted !== WidgetRegistry.hidden)
                        lastVisible = wanted
                    shown: wanted !== WidgetRegistry.hidden
                    style: wanted !== WidgetRegistry.hidden ? wanted : (lastVisible || WidgetRegistry.defaultStyle(modelData.id, "compact"))
                    growing: root.expanded || isFlashed
                    screen: root.screen
                    mode: root.mode
                }
            }
        }
    }

    Section {
        id: left
        name: "left"
        anchors.left: parent.left
    }

    Section {
        id: center
        name: "center"
        x: {
            const l = left.implicitWidth, c = center.implicitWidth, r = right.implicitWidth;
            // (whole pixels at rest, 2026-10-27/28: a half pixel blurred the text and wrapped the media disc's art)
            if (root.anchorCenter)
                return K.Kit.snap((root.width - c) / 2, root.snap);
            // packed: right after the left section, centered in the free space left over
            return K.Kit.snap(l + root.gapBetween(l, c) + Math.max(0, root.width - root.packedWidth(l, c, r)) / 2, root.snap);
        }
    }

    Section {
        id: right
        name: "right"
        anchors.right: parent.right
    }
}
