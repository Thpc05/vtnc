import QtQuick
import Quickshell.Widgets
import qs.core
import qs.services
import qs.components
import qs.theme
import qs.kit as K
import qs.dwidgets.quick.panels

// Wallpaper picker: search + matugen scheme + light/dark (one connected group in the apps' look,
// K.Kit.appStyle, 2026-10-17), grid of square thumbnails with a moving highlight frame and a name label.
// Type to filter, arrows to move, Enter/click to apply (the app stays open).
FocusScope {
    id: root

    // wide and short: two rows under the island
    readonly property int columns: 5
    readonly property int rows: 2
    readonly property int cell: 150
    readonly property int gap: 6

    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }
    // "scheme-tonal-spot" → "Tonal Spot" (an empty or odd scheme gives "", not a TypeError)
    readonly property string schemeName: (Store.theme.scheme ?? "").replace("scheme-", "").split("-").filter(w => w !== "").map(w => w[0].toUpperCase() + w.slice(1)).join(" ")

    readonly property var filtered: {
        const q = input.text.trim().toLowerCase();
        return q === "" ? Wallpapers.list : Wallpapers.list.filter(p => Wallpapers.name(p).toLowerCase().includes(q));
    }

    implicitWidth: columns * cell
    implicitHeight: bar.height + Tokens.spacing.s + rows * cell

    HoverSelect {
        id: hover
    }

    function opened() {
        hover.reset();
        Wallpapers.refresh();
        input.text = "";
        const i = filtered.indexOf(Wallpapers.current);
        grid.currentIndex = Math.max(0, i);
        grid.positionViewAtIndex(grid.currentIndex, GridView.Center);
        input.forceActiveFocus();
    }

    function move(dx: int, dy: int) {
        if (grid.count === 0)
            return;
        const i = grid.currentIndex + dx + dy * columns;
        grid.currentIndex = Math.max(0, Math.min(grid.count - 1, i));
    }

    function applyCurrent() {
        const path = filtered[grid.currentIndex];
        if (path)
            Wallpapers.apply(path);
    }

    // top bar ------------------------------------------------------------------
    Row {
        id: bar
        // the tiles are inset by half the gap: the bar lines up with them
        x: root.gap / 2
        width: parent.width - root.gap
        height: 44
        spacing: Tokens.spacing.s

        // the kit's search pill (caelestia's SearchBar)
        K.SearchBar {
            id: input
            width: parent.width - themeGroup.width - parent.spacing
            height: parent.height
            topPadding: 0
            bottomPadding: 0
            focus: true
            placeholderText: `Search ${Wallpapers.list.length} wallpapers…`
            font: Qt.font({
                family: K.Kit.family,
                pixelSize: Tokens.font.normal,
                variableAxes: K.Kit.axes
            })

            onTextChanged: grid.currentIndex = 0

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Left && input.text === "")
                    root.move(-1, 0);
                else if (e.key === Qt.Key_Right && input.text === "")
                    root.move(1, 0);
                else if (e.key === Qt.Key_Up)
                    root.move(0, -1);
                else if (e.key === Qt.Key_Down)
                    root.move(0, 1);
                else if (e.key === Qt.Key_Tab)
                    root.move(1, 0);
                else if (e.key === Qt.Key_Backtab)
                    root.move(-1, 0);
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                    root.applyCurrent();
                else
                    return;
                e.accepted = true;
            }
        }

        // a random wallpaper, the matugen scheme (‹ previous, the name = next) and light / dark (filled = light)
        ActionGroup {
            id: themeGroup
            width: 352
            anchors.verticalCenter: parent.verticalCenter
            rowHeight: parent.height
            look: K.Kit.appLook
            actions: [
                {
                    icon: "shuffle",
                    iconOnly: true,
                    run: () => Wallpapers.applyRandom()
                },
                {
                    icon: "chevron_left",
                    iconOnly: true,
                    run: () => Wallpapers.cycleScheme(-1)
                },
                {
                    text: root.schemeName,
                    icon: "palette",
                    run: () => Wallpapers.cycleScheme(1)
                },
                {
                    icon: Store.theme.light ? "light_mode" : "dark_mode",
                    iconOnly: true,
                    primary: Store.theme.light,
                    run: () => Store.theme.light = !Store.theme.light
                }
            ]
        }
    }

    // grid ---------------------------------------------------------------------
    GridView {
        id: grid
        anchors.top: bar.bottom
        anchors.topMargin: Tokens.spacing.s
        width: parent.width
        height: root.rows * root.cell
        cellWidth: root.cell
        cellHeight: root.cell
        clip: true
        model: root.filtered
        boundsBehavior: Flickable.StopAtBounds
        highlightFollowsCurrentItem: true
        highlightMoveDuration: K.Kit.anim.durations.expressiveFastSpatial
        preferredHighlightBegin: 0
        preferredHighlightEnd: height
        highlightRangeMode: GridView.ApplyRange

        highlight: Item {
            z: 10
            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: root.gap / 2
                radius: K.Kit.rounding.large
                color: "transparent"
                border.color: root.c.accent
                border.width: 3
            }

            // name label on a background band
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: root.gap / 2 + 3
                height: 26
                bottomLeftRadius: K.Kit.rounding.large - 3
                bottomRightRadius: K.Kit.rounding.large - 3
                color: root.c.kind === "tones" ? Qt.tint(Qt.alpha(K.Kit.expressive.container, 0.9), Qt.alpha(root.c.accent, 0.14)) : Qt.alpha(K.Kit.expressive.container, 0.85)

                StyledText {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.spacing.s
                    anchors.rightMargin: Tokens.spacing.s
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    font.pixelSize: Tokens.font.small
                    font.weight: Font.DemiBold
                    readonly property string path: root.filtered[grid.currentIndex] ?? ""
                    text: path === Wallpapers.current ? "Current" : Wallpapers.name(path)
                    color: path === Wallpapers.current || !root.c.shapes ? root.c.accent : Colors.overSurface
                }
            }
        }

        delegate: Item {
            id: cellItem
            required property string modelData
            required property int index

            width: grid.cellWidth
            height: grid.cellHeight

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: root.gap / 2
                radius: K.Kit.rounding.large
                color: K.Kit.expressive.container

                Image {
                    id: thumb
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize: Qt.size(256, 256)
                    source: Wallpapers.thumbFor(cellItem.modelData)
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity {
                        K.Anim {
                            type: K.Anim.FastEffects
                        }
                    }

                    // thumbnail may not exist yet: retry when the thumbnailer made progress
                    Connections {
                        target: Wallpapers
                        function onThumbsVersionChanged() {
                            if (thumb.status === Image.Error) {
                                thumb.source = "";
                                thumb.source = Wallpapers.thumbFor(cellItem.modelData);
                            }
                        }
                    }
                }

                // current wallpaper badge
                Rectangle {
                    visible: cellItem.modelData === Wallpapers.current
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: Tokens.spacing.s
                    width: 22
                    height: 22
                    // the look's "on" mark: Shapes a circle, the tones a rounded square
                    radius: root.c.shapes ? 11 : 7
                    color: root.c.accent

                    Icon {
                        anchors.centerIn: parent
                        icon: Icons.check
                        size: 14
                        color: Colors.overPrimary
                    }
                }
            }

            MouseArea {
                id: cellMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: m => hover.moved(cellMouse, m, () => grid.currentIndex = cellItem.index)
                onClicked: {
                    grid.currentIndex = cellItem.index;
                    root.applyCurrent();
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: grid.count === 0 && !Wallpapers.scanning
            text: Wallpapers.list.length === 0 ? `No images in ${Store.wallpapers.dir}` : "No matches"
            color: Colors.outline
        }
    }
}
