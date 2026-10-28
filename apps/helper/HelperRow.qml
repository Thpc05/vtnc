import QtQuick
import qs.theme
import qs.kit as K
import qs.dwidgets.quick.panels

// One item of a Helper list (2026-10-17): a section's caption with a hairline (or a blank one: a section
// carried over to the next column), or a row: its keys (caps), a mouse button and the place, or a
// command (mono) at the left, what it does at the right; the current one in the look (the container,
// a tint, a bar), a copy icon when it copies.
Item {
    id: row

    required property var item
    required property PanelColors c
    property int keyWidth: 220
    property bool wrap: false
    property bool current: false
    property bool copiedThis: false
    // on a section's card: the current row one step up from it
    property bool inCard: false
    readonly property bool isSection: item.kind === "section"

    signal hovered
    signal clicked

    // one height for captions and rows (52 when descriptions wrap): the two columns stay level
    readonly property int rowHeight: wrap ? 52 : 36
    implicitHeight: rowHeight

    // the current row's mark
    Rectangle {
        anchors.fill: parent
        visible: row.current && !row.isSection
        radius: K.Kit.rounding.large
        color: row.c.shapes ? (row.inCard ? K.Kit.expressive.off : K.Kit.expressive.container) : row.c.kind === "tones" ? Qt.tint(K.Kit.expressive.container, Qt.alpha(row.c.accent, K.Kit.expressive.light ? (row.inCard ? 0.24 : 0.16) : (row.inCard ? 0.2 : 0.12))) : "transparent"

        Rectangle {
            visible: row.c.kind === "tone"
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 20
            radius: 1.5
            color: row.c.accent
        }
    }

    // a section
    Item {
        anchors.fill: parent
        visible: row.isSection && (row.item.title ?? "") !== ""

        K.StyledText {
            id: caption
            x: Tokens.spacing.s
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: row.item.title ?? ""
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 12
            font.weight: 600
            color: row.c.accent
        }
        Rectangle {
            anchors.left: caption.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: Tokens.spacing.s
            anchors.verticalCenter: caption.verticalCenter
            height: 1
            color: row.c.faint
        }
    }

    // a row
    Item {
        anchors.fill: parent
        visible: !row.isSection

        Row {
            id: lead
            x: Tokens.spacing.s + 4
            width: row.keyWidth - x
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            clip: true

            Repeater {
                model: row.item.keys ?? (row.item.button ? [row.item.button] : [])

                KeyCap {
                    required property string modelData
                    text: modelData
                    c: row.c
                    current: row.current
                }
            }
            K.StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
                text: row.item.place ?? ""
                font.family: K.Kit.family
                font.variableAxes: K.Kit.axes
                font.pixelSize: 13
                font.weight: Font.Medium
                color: row.c.strong
            }
            K.StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
                width: Math.min(implicitWidth, lead.width)
                elide: Text.ElideRight
                text: row.item.key ?? ""
                font.family: K.Kit.monoFamily
                font.pixelSize: 12
                color: row.c.strong
            }
        }

        K.StyledText {
            id: desc
            anchors.left: parent.left
            anchors.leftMargin: row.keyWidth + Tokens.spacing.m
            anchors.right: copyIcon.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.item.text ?? ""
            wrapMode: row.wrap ? Text.Wrap : Text.NoWrap
            maximumLineCount: row.wrap ? 2 : 1
            elide: Text.ElideRight
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 13
            color: row.current || row.c.shapes ? row.c.strong : row.c.weak
        }

        K.MaterialIcon {
            id: copyIcon
            anchors.right: parent.right
            anchors.rightMargin: Tokens.spacing.m
            anchors.verticalCenter: parent.verticalCenter
            visible: !!row.item.copy && row.current
            text: row.copiedThis ? "check" : "content_copy"
            size: 16
            color: row.c.accent
        }
    }

    K.StateLayer {
        visible: !row.isSection
        radius: K.Kit.rounding.large
        color: row.c.strong
        stateOpacity: containsMouse && !row.current ? 0.08 : 0
        onEntered: row.hovered()
        onClicked: row.clicked()
    }
}
