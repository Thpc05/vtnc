import QtQuick
import qs.theme
import qs.kit as K

// A connected button group spanning its width (2026-10-16, as the notification card's actions): round
// outer ends, 4 px inner corners, 2 px apart. `actions`: [{ text, icon?, primary?, danger?, iconOnly?, enabled?,
// run }]; a primary one is filled with the accent, the others with the look's idle fill (Tone: tints, no
// solid fill). An `iconOnly` one is a small square-ish button (Forget's bin) and the others share the
// rest; a label that doesn't fit drops its icon first. Wraps into rows of `perRow` when given (presets).
Item {
    id: root

    property var look: null
    property var actions: []
    property int perRow: 0
    property int rowHeight: 32
    // the look's idle fill, unless the group sits on a fill of the same step (the launcher's current row)
    property color idleFill: c.off

    readonly property PanelColors c: PanelColors {
        look: root.look
    }
    readonly property int gap: 2
    readonly property int per: perRow > 0 ? perRow : Math.max(1, actions.length)
    readonly property var rows: {
        const out = [];
        for (let i = 0; i < actions.length; i += per)
            out.push(actions.slice(i, i + per));
        return out;
    }

    implicitHeight: rows.length * rowHeight + Math.max(0, rows.length - 1) * gap

    Column {
        width: root.width
        spacing: root.gap

        Repeater {
            model: root.rows

            Item {
                id: line
                required property var modelData
                required property int index
                // icon-only buttons are narrow, the others share what's left
                readonly property int small: modelData.filter(a => a.iconOnly).length
                readonly property real smallWidth: root.rowHeight + 8
                readonly property real part: (width - (modelData.length - 1) * root.gap - small * smallWidth) / Math.max(1, modelData.length - small)
                function xOf(i: int): real {
                    let x = 0;
                    for (let k = 0; k < i; k++)
                        x += (modelData[k].iconOnly ? smallWidth : part) + root.gap;
                    return x;
                }
                // the group's outer corners: the first / last row round their outer side only
                readonly property bool first: index === 0
                readonly property bool last: index === root.rows.length - 1
                width: root.width
                height: root.rowHeight

                Repeater {
                    model: line.modelData

                    Item {
                        id: button
                        required property var modelData
                        required property int index
                        readonly property bool primary: modelData.primary ?? false
                        // a confirm that destroys (Clear all, Delete note): filled in the error colour
                        readonly property bool danger: modelData.danger ?? false
                        readonly property bool usable: modelData.enabled ?? true
                        readonly property real outer: height / 2
                        readonly property real inner: 4
                        // one row: pill ends; several: only the group's four corners are round
                        // (not `left` / `right`: Item's anchor lines, FINAL)
                        readonly property bool isLeft: index === 0
                        readonly property bool isRight: index === line.modelData.length - 1
                        readonly property real tl: isLeft && line.first ? outer : inner
                        readonly property real bl: isLeft && line.last ? outer : inner
                        readonly property real tr: isRight && line.first ? outer : inner
                        readonly property real br: isRight && line.last ? outer : inner
                        readonly property bool iconOnly: modelData.iconOnly ?? false
                        readonly property bool hasIcon: (modelData.icon ?? "") !== ""
                        // the icon goes when the label wouldn't fit beside it
                        readonly property bool showIcon: hasIcon && (iconOnly || label.implicitWidth + 20 <= width - 12)
                        readonly property color fill: danger ? (root.c.kind === "tone" ? Qt.alpha(Colors.error, 0.2) : Colors.error) : root.c.kind === "tone" ? Qt.alpha(root.c.accent, primary ? 0.24 : 0.1) : primary ? root.c.accent : root.idleFill
                        readonly property color ink: danger ? (root.c.kind === "tone" ? Colors.error : Colors.overError) : primary && root.c.kind !== "tone" ? root.c.overAccent : root.c.shapes ? root.c.pal.over : root.c.accent

                        x: Math.round(line.xOf(index))
                        width: Math.round(line.xOf(index) + (iconOnly ? line.smallWidth : line.part)) - x
                        height: line.height
                        opacity: usable ? 1 : 0.5

                        Rectangle {
                            anchors.fill: parent
                            color: button.fill
                            topLeftRadius: button.tl
                            bottomLeftRadius: button.bl
                            topRightRadius: button.tr
                            bottomRightRadius: button.br
                            Behavior on color {
                                K.CAnim {}
                            }
                        }
                        K.StateLayer {
                            color: button.ink
                            disabled: !button.usable
                            topLeftRadius: button.tl
                            bottomLeftRadius: button.bl
                            topRightRadius: button.tr
                            bottomRightRadius: button.br
                            onClicked: button.modelData.run?.()
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            K.MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: button.showIcon
                                text: button.modelData.icon ?? ""
                                size: 16
                                fill: button.primary ? 1 : 0
                                color: button.ink
                            }
                            K.StyledText {
                                id: label
                                anchors.verticalCenter: parent.verticalCenter
                                visible: text !== "" && !button.iconOnly
                                width: Math.min(implicitWidth, button.width - 12 - (button.showIcon ? 20 : 0))
                                text: button.modelData.text ?? ""
                                elide: Text.ElideRight
                                font.family: K.Kit.family
                                font.variableAxes: K.Kit.axes
                                font.pixelSize: 12
                                font.weight: 600
                                color: button.ink
                            }
                        }
                    }
                }
            }
        }
    }
}
