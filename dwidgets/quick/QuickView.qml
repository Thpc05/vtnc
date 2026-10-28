import QtQuick
import qs.theme
import qs.kit as K
import "qwidgets.js" as Catalog

// Quick configs' Qwidgets (2026-10-11, redone in the Iwidget family; the toggles use it too): marks
// (QMark: shapes / tones / tone) laid out by the rect, either
//  - marks alone, as big as fit (24…48 px), centred; or
//  - labels: the mark, then the name and state beside it, as few per row as fit (a row ≥ 36 px tall,
//    each ≥ 96 px wide), with a "›" for the panel.
// `labels`: auto (by the size) · on (whenever a row fits) · off. No boxes behind them (the island's
// language): only the marks fill. `interactive: false` leaves the input to the owner (the toggles).
Item {
    id: root

    property var models: ({})
    property var items: []
    property string look: "shapes"
    property var pal: K.Kit.bare
    property color tone: pal.accent
    property color overTone: pal.overAccent
    property int gap: 8
    property int weight: 400
    property string labels: "auto"
    // the Qwidgets' panels can open (the entry expands)
    property bool panels: false
    property bool interactive: true
    // the Shapes look's random shapes (the Dwidget's options.randomShapes)
    property bool randomShapes: true
    // the owner's pressed state when it takes the input
    property bool pressed: false
    signal openPanel(string key)

    // the size the arrangement is chosen by: the Dwidget's target rect, not the animated one (at a
    // threshold, e.g. the 2x1 toggle's 36 px row, a moving cell flipped labels on and off)
    property real layoutWidth: width
    property real layoutHeight: height
    readonly property var arranged: labels === "off" ? ({
            kind: "icons",
            per: 0
        }) : Catalog.arrange(items.length, layoutWidth, layoutHeight, gap, labels === "on" ? 28 : 36, 96)

    // the label colours, per look
    function titleColor(on: bool): color {
        return look === "shapes" ? pal.over : on ? tone : Qt.alpha(tone, look === "tone" ? 0.8 : 0.55);
    }
    function statusColor(on: bool): color {
        return look === "shapes" ? pal.overVariant : Qt.alpha(tone, on ? 0.7 : 0.45);
    }

    K.StyledText {
        anchors.centerIn: parent
        visible: root.items.length === 0
        text: "No Qwidgets chosen"
        color: root.pal.overVariant
    }

    // whether a point (in this view) is on the first Qwidget's mark (a few px around it): the Wi-Fi /
    // Bluetooth Dwidgets split the click there (the mark toggles, the rest opens the panel; 2026-10-15)
    function onMark(px: real, py: real): bool {
        const l = layout.item;
        if (!l)
            return false;
        if (arranged.kind === "icons")
            return true;
        const top = (l.rowHeight - l.side) / 2;
        return px >= -4 && px <= l.side + 4 && py >= top - 4 && py <= top + l.side + 4;
    }

    Loader {
        id: layout
        anchors.fill: parent
        active: root.items.length > 0
        sourceComponent: root.arranged.kind === "icons" ? marks : labelled
    }

    component Mark: QMark {
        look: root.look
        pal: root.pal
        tone: root.tone
        overTone: root.overTone
        weight: root.weight
        shapesRandom: root.randomShapes
        // even: the glyph snaps to whole pixels
        iconSize: 2 * Math.round(Math.max(12, Math.min(24, width * 0.5)) / 2)
    }

    // marks alone, as big as fit, centred
    Component {
        id: marks

        Item {
            id: grid
            readonly property var shape: Catalog.squares(root.items.length, width, height, root.gap)
            readonly property real side: 2 * Math.floor(Math.max(24, Math.min(48, shape.side)) / 2)

            Column {
                x: Math.round((parent.width - width) / 2)
                y: Math.round((parent.height - height) / 2)
                spacing: root.gap

                Repeater {
                    model: Catalog.split(root.items, grid.shape.rows)

                    Row {
                        id: line
                        required property var modelData
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: root.gap

                        Repeater {
                            model: line.modelData

                            Mark {
                                id: mark
                                required property string modelData
                                width: grid.side
                                height: grid.side
                                q: root.models[modelData] ?? null
                                pressed: root.interactive ? input.pressed : root.pressed

                                QInput {
                                    id: input
                                    visible: root.interactive
                                    radius: mark.shapeRadius
                                    color: mark.on ? mark.overAccent : root.pal.over
                                    qid: mark.modelData
                                    q: mark.q
                                    onOpenPanel: key => root.openPanel(key)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // labels: rows sharing the height, `per` in each
    Component {
        id: labelled

        Column {
            id: column
            readonly property int per: Math.max(1, root.arranged.per)
            readonly property var rows: Catalog.split(root.items, Math.ceil(root.items.length / per))
            // by the target height too (the state line shows from 36 px, the 2x1 toggle's exact row: by the
            // animated height it flickered while the cell moved)
            readonly property real rowHeight: Math.floor((root.layoutHeight - spacing * (rows.length - 1)) / Math.max(1, rows.length))
            // one size for every mark: even, 24…40
            readonly property real side: 2 * Math.floor(Math.max(24, Math.min(40, rowHeight)) / 2)
            spacing: root.gap

            Repeater {
                model: column.rows

                Row {
                    id: row
                    required property var modelData
                    width: column.width
                    height: column.rowHeight
                    spacing: root.gap

                    Repeater {
                        model: row.modelData

                        Item {
                            id: label
                            required property string modelData
                            readonly property QtObject q: root.models[modelData] ?? null
                            readonly property bool on: q?.active ?? false
                            readonly property bool chevron: root.panels && (Catalog.QWIDGETS[Catalog.idOf(modelData)]?.panel ?? false) && !(q?.opensPanel ?? false)
                            width: Math.floor((row.width - root.gap * (column.per - 1)) / column.per)
                            height: row.height

                            QInput {
                                visible: root.interactive
                                radius: Math.min(height / 2, K.Kit.rounding.extraLarge)
                                color: root.pal.over
                                qid: label.modelData
                                q: label.q
                                onOpenPanel: key => root.openPanel(key)
                                onPressedChanged: labelMark.pressed = pressed
                            }
                            Mark {
                                id: labelMark
                                y: Math.round((parent.height - height) / 2)
                                width: column.side
                                height: column.side
                                q: label.q
                                pressed: root.pressed
                            }
                            Column {
                                anchors.left: labelMark.right
                                anchors.leftMargin: Math.round(column.side * 0.3)
                                anchors.right: more.visible ? more.left : parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: label.q?.available ?? true ? 1 : 0.38

                                K.StyledText {
                                    width: parent.width
                                    text: label.q?.title ?? ""
                                    font.family: K.Kit.family
                                    font.variableAxes: K.Kit.axes
                                    font.pixelSize: 13
                                    font.weight: root.look !== "shapes" && (label.on || label.q?.danger) ? Font.Bold : Font.DemiBold
                                    color: label.q?.danger ? Colors.error : root.titleColor(label.on)
                                    elide: Text.ElideRight
                                }
                                K.StyledText {
                                    width: parent.width
                                    visible: text !== "" && label.height >= 36
                                    text: label.q?.status ?? ""
                                    font.family: K.Kit.family
                                    font.variableAxes: K.Kit.axes
                                    font.pixelSize: 11
                                    color: root.statusColor(label.on)
                                    elide: Text.ElideRight
                                }
                            }
                            // the "›": opens the panel
                            Item {
                                id: more
                                visible: label.chevron && root.interactive
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24
                                height: 24

                                K.StateLayer {
                                    radius: width / 2
                                    color: root.pal.over
                                    disabled: !(label.q?.available ?? false)
                                    onClicked: root.openPanel(label.modelData)
                                }
                                K.MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "chevron_right"
                                    size: 18
                                    color: root.statusColor(false)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
