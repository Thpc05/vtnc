import QtQuick
import qs.theme
import qs.kit as K
import qs.components
import qs.dwidgets

// Debug Dwidget: shows what the layout engine gave it (style, size, expanded). For trying the
// expand modes (Settings → Dashboard → Demo layout).
Dwidget {
    id: root

    Card {
        anchors.fill: parent
        radius: K.Kit.expressive.radius
        color: root.expanded ? K.Kit.expressive.high : K.Kit.expressive.container
        border.width: root.expanded ? 2 : 0
        border.color: Colors.primary

        Behavior on color {
            K.CAnim {}
        }

        Column {
            anchors.centerIn: parent
            spacing: Tokens.spacing.xs

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                icon: Icons.squaresFour
                color: root.expanded ? Colors.primary : Colors.overBackground
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.style + " · " + root.size.w + "×" + root.size.h
                font.pixelSize: Tokens.font.small
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.expanded
                text: "expanded"
                font.pixelSize: Tokens.font.small
                color: Colors.primary
            }
        }
    }
}
