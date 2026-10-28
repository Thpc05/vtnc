import QtQuick
import QtQuick.Layouts
import qs.theme

// An icon + text button (caelestia's IconTextButton, ported): the colors of TextButton, the icon
// 1.2 × the text and filled when checked.
ButtonBase {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text
    property alias spacing: row.spacing

    readonly property alias iconLabel: iconLabel
    readonly property alias label: label

    horizontalPadding: Kit.padding.medium
    verticalPadding: Kit.padding.small

    activeColour: type === ButtonBase.Filled ? Colors.primary : Colors.secondary
    inactiveColour: {
        if (!isToggle && type === ButtonBase.Filled)
            return Colors.primary;
        return type === ButtonBase.Filled ? Kit.expressive.container : Colors.secondaryContainer;
    }
    activeOnColour: {
        if (type === ButtonBase.Text)
            return Colors.primary;
        return type === ButtonBase.Filled ? Colors.overPrimary : Colors.overSecondary;
    }
    inactiveOnColour: {
        if (!isToggle && type === ButtonBase.Filled)
            return Colors.overPrimary;
        if (type === ButtonBase.Text)
            return Colors.primary;
        return type === ButtonBase.Filled ? Colors.overSurface : Colors.overSecondaryContainer;
    }

    implicitWidth: row.implicitWidth + horizontalPadding * 2
    implicitHeight: row.implicitHeight + verticalPadding * 2

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Kit.spacing.small

        MaterialIcon {
            id: iconLabel

            Layout.alignment: Qt.AlignVCenter
            color: root.onColour
            fill: root.internalChecked ? 1 : 0
            size: Math.round(root.font.pointSize * 1.2 * 4 / 3)

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StyledText {
            id: label

            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: 1
            color: root.onColour
            font: root.font
        }
    }
}
