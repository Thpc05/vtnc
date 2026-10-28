import QtQuick
import qs.components
import qs.theme
import qs.dwidgets.quick.panels
import qs.kit as K

// One setting: label (+ optional description) on the left, control on the right.
//   SettingRow { label: "Expand on hover"; Switch { ... } }
// Narrow rows (a column, a side panel) stack: label and description on top, control below.
Item {
    id: root

    property string label: ""
    property string description: ""
    default property alias control: slot.data
    // label on top, control below (automatic when narrow)
    property bool stacked: width > 0 && width < 360

    // the apps' look (strong label, weak description)
    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }

    implicitHeight: (stacked ? texts.implicitHeight + Tokens.spacing.xs + slot.height : Math.max(texts.implicitHeight, slot.height)) + 2 * Tokens.spacing.s
    width: parent?.width ?? 0

    Column {
        id: texts
        x: 0
        y: root.stacked ? Tokens.spacing.s : (root.height - implicitHeight) / 2
        width: root.stacked ? root.width : Math.max(0, root.width - slot.width - Tokens.spacing.m)
        spacing: 1

        StyledText {
            width: parent.width
            text: root.label
            elide: Text.ElideRight
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: Tokens.font.normal
            font.weight: Font.DemiBold
            color: root.c.strong
        }
        StyledText {
            width: parent.width
            visible: root.description !== ""
            text: root.description
            wrapMode: Text.Wrap
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: Tokens.font.small
            color: root.c.weak
        }
    }

    // controls that can wrap (Segmented) get the room they have: the whole row when stacked, else
    // what the label leaves
    readonly property real controlMaxWidth: stacked ? width : Math.max(120, width * 0.6)

    function fitControls() {
        for (let i = 0; i < slot.children.length; i++)
            if (slot.children[i].hasOwnProperty("maxWidth"))
                slot.children[i].maxWidth = Qt.binding(() => root.controlMaxWidth);
    }
    Component.onCompleted: fitControls()

    Item {
        id: slot
        onChildrenChanged: root.fitControls()
        x: root.stacked ? 0 : root.width - width
        y: root.stacked ? texts.y + texts.implicitHeight + Tokens.spacing.xs : (root.height - height) / 2
        width: childrenRect.width
        height: childrenRect.height
    }
}
