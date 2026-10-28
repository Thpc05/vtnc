import QtQuick
import qs.components
import qs.theme
import qs.kit as K

// A card grouping an Iwidget's options in the Layout detail panel (user: the general options and the
// compact / expanded ones read as one list before): a container card with a small title over its rows.
Rectangle {
    id: root

    property string title
    default property alias content: body.data
    readonly property real pad: Tokens.spacing.m

    implicitHeight: body.implicitHeight + 2 * pad
    radius: K.Kit.rounding.large
    color: K.Kit.expressive.container

    Column {
        id: body
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad

        StyledText {
            bottomPadding: Tokens.spacing.xs
            text: root.title
            font.weight: Font.DemiBold
            color: Colors.primary
        }
    }
}
