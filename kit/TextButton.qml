import QtQuick
import qs.theme

// A text button (caelestia's TextButton, ported). Filled: primary (as a toggle: off = container);
// Tonal: secondaryContainer → secondary; Text: primary text, no background.
ButtonBase {
    id: root

    property alias text: label.text
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

    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: label.implicitHeight + verticalPadding * 2

    StyledText {
        id: label

        anchors.centerIn: parent
        color: root.onColour
        font: root.font
    }
}
