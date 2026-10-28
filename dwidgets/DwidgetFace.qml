import QtQuick
import qs.core
import qs.theme
import qs.kit as K
import qs.components

// A Dwidget drawn as a simple box: icon, title and size. Used where the real Dwidget doesn't fit
// or can't be shown (the settings editor at a small scale, `preview: false`, the drag ghost).
Card {
    id: face

    property string widgetId
    property string size
    property bool highlighted: false
    readonly property var info: DwidgetRegistry.widgets[widgetId] ?? ({})

    radius: K.Kit.expressive.radius
    color: highlighted ? Colors.primary : K.Kit.expressive.container

    Column {
        anchors.centerIn: parent
        width: parent.width - 2 * Tokens.spacing.xs
        spacing: 2

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: Icons[face.info.icon] ?? Icons.squaresFour
            size: 16
            color: face.highlighted ? Colors.overPrimary : Colors.primary
        }
        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: face.info.title ?? face.widgetId
            font.pixelSize: Tokens.font.small
            font.weight: Font.DemiBold
            color: face.highlighted ? Colors.overPrimary : Colors.overBackground
        }
        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: face.size !== ""
            text: face.size.replace("x", "×")
            font.pixelSize: Tokens.font.small - 2
            color: face.highlighted ? Colors.overPrimary : Colors.outline
        }
    }
}
