import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.core
import qs.theme
import qs.kit as K

// System tray icons (stage 7, 2026-10-08). Left click activates, right click (or menu-only items)
// opens the menu, middle click the secondary action, the wheel scrolls. Styles:
//  - icons (A): the row, a round state layer on hover
//  - tint (D, was "mono"; caelestia's recolour): each icon tinted to one colour keeping its shading
//    (TintedIcon.qml; island.tray.tintColor, primary by default)
// Each also comes on the island card (Card variants: `pal`; the old "pill" style became Icons + Card).
// Compact (caelestia's; was the "chevron", then the "compact" style) is an option per island mode since
// 2026-10-11 (user), for either style: island.tray.<mode>.fold folds the icons behind a small chevron,
// "left" (<: the icons open to its left) or "right" (>: to its right), "off" never; a click unfolds them
// inline, again folds them (the arrow turns; they fold back when the island collapses).
Item {
    id: root

    property string style: "icons"
    // from the frame: the island mode and the palette (the island card's for the Card variants)
    property string mode: "compact"
    property var pal: K.Kit.bare
    readonly property var items: SystemTray.items.values.filter(i => i.status !== Status.Passive)
    // folded behind the chevron in this mode (island.tray.<mode>.fold: off / left / right, where the icons
    // open); `open` = unfolded (folded again when the island collapses)
    readonly property string fold: Store.island.tray?.[mode]?.fold ?? "off"
    readonly property bool folds: fold === "left" || fold === "right"
    property bool open: false
    onModeChanged: if (mode === "compact")
        open = false
    // the last icon left: fold again for the next one
    onItemsChanged: if (items.length === 0)
        open = false
    readonly property bool showsIcons: !folds || open
    // tint: the icons' colour (island.tray.tintColor, primary by default); on hover
    // the hovered one turns primary, or the text colour when that's primary already
    readonly property color tintColor: {
        switch (Store.island.tray?.tintColor) {
        case "surface":
            return pal.over;
        case "variant":
            return pal.overVariant;
        case "secondary":
            return Colors.secondary;
        case "tertiary":
            return Colors.tertiary;
        default:
            return Colors.primary;
        }
    }
    readonly property color tintHover: Store.island.tray?.tintColor === "primary" || !Store.island.tray?.tintColor ? pal.over : Colors.primary
    readonly property int cell: 22

    // nothing in the tray: no width at all (the chevron kept its room after the last app left)
    implicitWidth: items.length === 0 ? 0 : (folds ? chevron.width + (open ? 2 : 0) : 0) + (showsIcons ? row.implicitWidth : 0)
    implicitHeight: 24
    visible: items.length > 0

    Item {
        id: chevron
        visible: root.folds
        anchors.verticalCenter: parent.verticalCenter
        // <: after the icons (they open to its left); >: before them
        x: root.fold === "left" && root.open ? row.implicitWidth + 2 : 0
        // from `folds`, not `visible`: visibility is inherited, and the island's slot starts invisible at
        // width 0, so the chevron never got a width (the compact tray never showed)
        // narrow (user, 2026-10-15): the chevron's ink is ~6 px; even, so it centres on whole pixels
        width: root.folds ? 12 : 0
        height: 22

        K.StateLayer {
            radius: width / 2
            color: root.pal.over
            onClicked: root.open = !root.open
        }
        K.MaterialIcon {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            text: root.fold === "left" ? "chevron_left" : "chevron_right"
            size: 18
            rotation: root.open ? 180 : 0
            color: root.pal.overVariant
            Behavior on rotation {
                K.Anim {
                    type: K.Anim.FastSpatial
                }
            }
        }
    }

    Row {
        id: row
        x: root.fold === "right" ? chevron.width + 2 : 0
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showsIcons
        spacing: 2

        Repeater {
            model: root.items

            Item {
                id: entry
                required property SystemTrayItem modelData
                width: root.cell
                height: root.cell

                K.StateLayer {
                    id: hover
                    radius: width / 2
                    color: root.pal.over
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: m => {
                        const item = entry.modelData;
                        if (m.button === Qt.MiddleButton) {
                            item.secondaryActivate();
                        } else if (m.button === Qt.RightButton || item.onlyMenu) {
                            if (item.hasMenu) {
                                const win = QsWindow.window;
                                const p = entry.mapToItem(win.contentItem, 0, entry.height + 6);
                                item.display(win, p.x, p.y);
                            }
                        } else {
                            item.activate();
                        }
                    }
                }
                WheelHandler {
                    onWheel: w => entry.modelData.scroll(w.angleDelta.y, false)
                }

                TintedIcon {
                    id: icon
                    x: 3
                    y: 3
                    implicitSize: 16
                    source: entry.modelData.icon
                    tint: root.style === "tint"
                    colour: hover.containsMouse ? root.tintHover : root.tintColor
                }
            }
        }
    }
}
