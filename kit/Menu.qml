pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import Quickshell
import qs.theme

// A dropdown menu (caelestia's Menu, ported): a surfaceContainerLow card at elevation 2 that
// unfolds from `attachTo` (scaleY 0.1 → 1), its items as rows with an icon; the active one is
// tertiaryContainer with medium corners. A click outside closes it. It fills the window's root
// item (vtnc: the topmost parent of `attachTo`; caelestia used its drawers' interactions layer).
MouseArea {
    id: root

    enum Side {
        Top,
        Bottom,
        Left,
        Right
    }

    required property Item attachTo
    property int attachSideX: Menu.Right
    property int attachSideY: Menu.Bottom
    property int thisSideX: Menu.Right
    property int thisSideY: Menu.Top
    property real marginX
    property real marginY

    property list<MenuItem> items
    property MenuItem active: items[0] ?? null
    property bool expanded
    property real maxHeight: 320

    signal itemSelected(item: MenuItem)

    parent: {
        let node = root.attachTo;
        while (node && node.parent)
            node = node.parent;
        return node || root.parent;
    }
    anchors.fill: parent
    z: 1000

    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    onClicked: expanded = false

    opacity: expanded ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    TransformWatcher {
        id: watcher

        a: root.parent
        b: root.attachTo
    }

    Elevation {
        id: menu

        x: {
            watcher.transform; // mapToItem isn't reactive: this forces updates
            const item = root.attachTo;
            let off = root.attachSideX === Menu.Left ? 0 : item.width;
            if (root.thisSideX === Menu.Right)
                off -= width;
            return item.mapToItem(root.parent, off, 0).x + root.marginX;
        }
        y: {
            watcher.transform;
            const item = root.attachTo;
            let off = root.attachSideY === Menu.Top ? 0 : item.height;
            if (root.thisSideY === Menu.Bottom)
                off -= height;
            return item.mapToItem(root.parent, 0, off).y + root.marginY;
        }

        radius: Kit.rounding.large
        level: 2

        implicitWidth: Math.max(200, column.implicitWidth + Kit.padding.extraSmall * 2)
        implicitHeight: Math.min(root.maxHeight, column.implicitHeight + Kit.padding.extraSmall * 2)

        transform: Scale {
            yScale: root.expanded ? 1 : 0.1
            origin.y: root.thisSideY === Menu.Bottom ? menu.height : 0

            Behavior on yScale {
                Anim {}
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onWheel: e => e.accepted = true
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colors.surfaceContainerLow

            Flickable {
                id: flickable

                anchors.fill: parent
                anchors.margins: Kit.padding.extraSmall
                contentWidth: width
                contentHeight: column.implicitHeight
                clip: true

                interactive: contentHeight > height

                QQC.ScrollBar.vertical: ScrollBar {
                    flickable: flickable
                }

                ColumnLayout {
                    id: column

                    width: parent.width
                    spacing: 0

                    Repeater {
                        id: repeater

                        model: root.items

                        StyledRect {
                            id: item

                            required property int index
                            required property MenuItem modelData
                            readonly property bool active: modelData === root.active

                            Layout.fillWidth: true
                            implicitWidth: menuOptionRow.implicitWidth + Kit.padding.medium * 2
                            implicitHeight: menuOptionRow.implicitHeight + Kit.padding.medium * 2

                            radius: active ? Kit.rounding.medium : Kit.rounding.extraSmall
                            topLeftRadius: index === 0 ? Kit.rounding.medium : radius
                            topRightRadius: index === 0 ? Kit.rounding.medium : radius
                            bottomLeftRadius: index === repeater.count - 1 ? Kit.rounding.medium : radius
                            bottomRightRadius: index === repeater.count - 1 ? Kit.rounding.medium : radius

                            color: Qt.alpha(Colors.tertiaryContainer, active ? 1 : 0)

                            Behavior on radius {
                                Anim {}
                            }

                            StateLayer {
                                topLeftRadius: parent.topLeftRadius
                                topRightRadius: parent.topRightRadius
                                bottomLeftRadius: parent.bottomLeftRadius
                                bottomRightRadius: parent.bottomRightRadius

                                color: item.active ? Colors.overTertiaryContainer : Colors.overSurface
                                disabled: !root.expanded
                                onClicked: {
                                    root.itemSelected(item.modelData);
                                    root.active = item.modelData;
                                    item.modelData.clicked();
                                    root.expanded = false;
                                }
                            }

                            RowLayout {
                                id: menuOptionRow

                                anchors.fill: parent
                                anchors.margins: Kit.padding.medium
                                spacing: Kit.spacing.small

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: text !== ""
                                    text: item.modelData?.icon ?? ""
                                    color: item.active ? Colors.overTertiaryContainer : Colors.overSurfaceVariant
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    text: item.modelData?.text ?? ""
                                    color: item.active ? Colors.overTertiaryContainer : Colors.overSurface
                                }

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: text !== ""
                                    text: item.modelData?.trailingIcon ?? ""
                                    color: item.active ? Colors.overTertiaryContainer : Colors.overSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
