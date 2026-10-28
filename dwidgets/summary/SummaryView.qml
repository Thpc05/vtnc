import QtQuick
import qs.dwidgets
import qs.kit as K

// A summary Dwidget's body (2026-10-17, user): an app's latest items on the dashboard. Two layouts, by the
// size (Widget.qml):
//  - badge (1x1, 2x1, 1x2): the mark, and the count beside it (wide) or under it (tall) when it fits; a
//    click opens the app
//  - list (2x2 and up): a header (the mark, the title and the count; a click opens the app; the source's
//    action, Notes' + or Dino's ▶, at the right), then as many items as fit (two lines from 3 cells wide;
//    a wide card in columns of 240 px or more). A click on an item acts in place (the source's `activate`)
// Looks, the Iwidget family: Shapes plain text (surface / variant) with the mark on an accent M3 shape,
// Two tones in the tone with the mark on a tone square, Tone in the tone with the bare mark.
Item {
    id: root

    // the source: title, icon, empty, action, count, countText, items, opened(), openApp(), activate(item), run()
    required property QtObject source
    property string look: "shapes"
    property var pal: K.Kit.bare
    property color tone: pal.accent
    property color overTone: pal.overAccent
    property bool randomShapes: true
    property bool interactive: true
    // badge · list
    property string layout: "list"
    // the rect it's going to (a layout by size doesn't flip mid-move)
    property real targetWidth: width
    property real targetHeight: height

    readonly property bool shapes: look === "shapes"
    readonly property color strong: shapes ? pal.over : tone
    // the weak tone, mode-aware (11 px text stays readable on a light card)
    readonly property color weak: shapes ? pal.overVariant : Qt.alpha(tone, look === "tone" ? (K.Kit.expressive.light ? 0.9 : 0.72) : (K.Kit.expressive.light ? 0.9 : 0.62))

    // badge -------------------------------------------------------------------
    Item {
        id: badge
        anchors.fill: parent
        visible: root.layout === "badge"

        readonly property bool wide: root.targetWidth >= root.targetHeight * 1.5
        readonly property bool tall: root.targetHeight >= root.targetWidth * 1.5
        readonly property int mark: 2 * Math.floor(Math.min(wide ? root.targetHeight : root.targetWidth, 48) / 2)
        readonly property bool texts: wide ? root.targetWidth - mark >= 52 : tall && root.targetHeight - mark >= 36
        // the title under the count only when it fits (a narrow tall badge shows the count alone)
        readonly property bool titleFits: wide || titleMetrics.advanceWidth <= root.targetWidth
        TextMetrics {
            id: titleMetrics
            font.family: K.Kit.family
            font.pixelSize: 11
            text: root.source.title
        }

        SummaryMark {
            id: badgeMark
            width: badge.mark
            height: badge.mark
            x: badge.wide && badge.texts ? 0 : Math.round((parent.width - width) / 2)
            y: badge.wide || !badge.texts ? Math.round((parent.height - height) / 2) : Math.round((parent.height - height - 6 - (badge.titleFits ? 28 : 14)) / 2)
            look: root.look
            pal: root.pal
            tone: root.tone
            overTone: root.overTone
            icon: root.source.icon
            randomShapes: root.randomShapes
        }
        Column {
            visible: badge.texts
            x: badge.wide ? badgeMark.width + 10 : 0
            y: badge.wide ? Math.round((parent.height - height) / 2) : badgeMark.y + badgeMark.height + 6
            width: badge.wide ? parent.width - x : parent.width
            spacing: 3

            CapText {
                width: parent.width
                height: 14
                family: K.Kit.family
                horizontalAlignment: badge.wide ? Text.AlignLeft : Text.AlignHCenter
                text: root.source.count > 0 ? String(root.source.count) : "0"
                pixelSize: 14
                weight: 700
                color: root.strong
            }
            CapText {
                visible: badge.titleFits
                width: parent.width
                height: 11
                family: K.Kit.family
                horizontalAlignment: badge.wide ? Text.AlignLeft : Text.AlignHCenter
                text: root.source.title
                pixelSize: 11
                weight: 500
                color: root.weak
            }
        }
        K.StateLayer {
            visible: root.interactive
            radius: Math.min(width, height) / 2
            color: root.strong
            onClicked: root.source.openApp()
        }
    }

    // list --------------------------------------------------------------------
    Item {
        id: list
        anchors.fill: parent
        visible: root.layout === "list"

        readonly property int headerHeight: 36
        readonly property real free: root.targetHeight - headerHeight
        // a wide card (6x2, 8x2…) flows the rows into columns, each at least 240 px (2026-10-27)
        readonly property int columnGap: 8
        readonly property int cols: Math.max(1, Math.min(4, Math.floor((root.targetWidth + columnGap) / (240 + columnGap))))
        readonly property real colWidth: (root.targetWidth - (cols - 1) * columnGap) / cols
        // two lines only when wide, one of the rows shown has a second line, and it doesn't cost a row
        // below two
        readonly property int fitsOne: Math.max(0, Math.floor(free / 36))
        readonly property int fitsTwo: Math.max(0, Math.floor(free / 44))
        readonly property bool twoLines: colWidth >= 220 && (fitsTwo >= 2 || fitsTwo === fitsOne) && root.source.items.slice(0, fitsTwo * cols).some(i => (i.sub ?? "") !== "")
        readonly property int baseRow: twoLines ? 44 : 36
        readonly property int fits: twoLines ? fitsTwo : fitsOne
        // a little of the leftover spread over the rows; the rest stays at the bottom
        readonly property int rowHeight: fits > 0 ? Math.min(baseRow + 4, Math.floor(free / fits)) : baseRow
        // narrow (a 2-wide card): no mark in the header, the title and count get the room
        readonly property bool compact: root.targetWidth < 150

        // header
        Item {
            id: header
            width: parent.width
            height: list.headerHeight

            SummaryMark {
                id: headMark
                x: 2
                visible: !list.compact
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                look: root.look
                pal: root.pal
                tone: root.tone
                overTone: root.overTone
                icon: root.source.icon
                randomShapes: root.randomShapes
            }
            Column {
                anchors.left: list.compact ? parent.left : headMark.right
                anchors.leftMargin: list.compact ? 6 : 8
                anchors.right: actionButton.visible ? actionButton.left : parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                K.StyledText {
                    width: parent.width
                    text: root.source.title
                    elide: Text.ElideRight
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: root.strong
                }
                K.StyledText {
                    width: parent.width
                    text: root.source.countText
                    elide: Text.ElideRight
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 11
                    color: root.weak
                }
            }
            K.StateLayer {
                visible: root.interactive
                radius: 14
                color: root.strong
                onClicked: root.source.openApp()
            }

            // the source's action (Notes: a new note), over the header's click
            Item {
                id: actionButton
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                visible: root.source.action !== ""
                width: 32
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: root.shapes ? width / 2 : 10
                    color: root.shapes ? Qt.alpha(root.pal.over, 0.1) : root.look === "tones" ? Qt.alpha(root.tone, 0.16) : "transparent"
                }
                K.MaterialIcon {
                    x: Math.round((parent.width - width) / 2)
                    y: Math.round((parent.height - height) / 2)
                    text: root.source.action
                    size: 20
                    color: root.shapes ? root.pal.over : root.tone
                }
                K.StateLayer {
                    visible: root.interactive
                    radius: root.shapes ? width / 2 : 10
                    color: root.strong
                    onClicked: root.source.run()
                }
            }
        }

        Grid {
            y: list.headerHeight
            width: parent.width
            columns: list.cols
            rows: Math.max(1, list.fits)
            flow: Grid.TopToBottom
            columnSpacing: list.columnGap

            Repeater {
                model: root.source.items.slice(0, list.fits * list.cols)

                SummaryRow {
                    required property var modelData
                    width: list.colWidth
                    height: list.rowHeight
                    item: modelData
                    view: root
                    twoLines: list.twoLines
                    interactive: root.interactive
                    done: (root.source.done ?? "") !== "" && root.source.done === String(modelData.key)
                    onClicked: root.source.activate(modelData)
                }
            }
        }

        K.StyledText {
            visible: root.source.items.length === 0 && list.fits > 0
            y: list.headerHeight + Math.round((parent.height - list.headerHeight - height) / 2)
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.source.empty
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 12
            color: root.weak
        }
    }
}
