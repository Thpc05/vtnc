import QtQuick
import QtQuick.Templates as T
import qs.theme

// An M3 radio button (caelestia's StyledRadioButton, ported): a 20 px ring (primary when checked)
// with an 8 px primary dot, a state layer around it, and the `text` beside it.
T.RadioButton {
    id: root

    font: Kit.font.body.small

    implicitWidth: implicitIndicatorWidth + implicitContentWidth + Kit.spacing.medium
    implicitHeight: Math.max(implicitIndicatorHeight, implicitContentHeight)

    indicator: Rectangle {
        id: outerCircle

        implicitWidth: 20
        implicitHeight: 20
        radius: Kit.rounding.full
        color: "transparent"
        border.color: root.checked ? Colors.primary : Colors.overSurfaceVariant
        border.width: 2
        anchors.verticalCenter: parent.verticalCenter

        StateLayer {
            anchors.margins: -Kit.padding.small
            radius: Kit.rounding.full
            color: root.checked ? Colors.overSurface : Colors.primary
            z: -1
            onClicked: root.click()
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 8
            implicitHeight: 8

            radius: Kit.rounding.full
            color: Qt.alpha(Colors.primary, root.checked ? 1 : 0)
        }

        Behavior on border.color {
            CAnim {}
        }
    }

    contentItem: StyledText {
        text: root.text
        font: root.font
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: outerCircle.right
        anchors.right: parent.right
        anchors.leftMargin: Kit.spacing.medium
        elide: Text.ElideRight
    }
}
