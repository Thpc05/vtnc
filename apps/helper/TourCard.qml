import QtQuick
import qs.dwidgets.quick.panels
import qs.kit as K

// A card of the About tab's tour (2026-10-17, user): one part of vtnc, its symbol on an M3 shape
// (Shapes) or a tinted square (the tones), a title and two lines; a click opens it (`open()`).
Rectangle {
    id: root

    property string icon
    property string title
    property string text
    property string shape: "cookie7"
    property var open: null
    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }

    radius: K.Kit.rounding.large
    color: c.shapes ? K.Kit.expressive.container : c.kind === "tones" ? Qt.tint(K.Kit.expressive.container, Qt.alpha(c.accent, K.Kit.expressive.light ? 0.08 : 0.06)) : "transparent"
    border.width: c.kind === "tone" ? 1 : 0
    border.color: Qt.alpha(c.accent, 0.22)

    Item {
        id: mark
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 44

        K.M3Shape {
            anchors.fill: parent
            visible: root.c.shapes
            shape: root.shape
            samples: 60
            color: root.c.accent
        }
        Rectangle {
            anchors.fill: parent
            visible: !root.c.shapes
            radius: 13
            color: root.c.kind === "tones" ? root.c.accent : Qt.alpha(root.c.accent, 0.12)
        }
        K.MaterialIcon {
            anchors.centerIn: parent
            text: root.icon
            size: 22
            fill: 1
            color: root.c.kind === "tone" ? root.c.accent : root.c.overAccent
        }
    }

    Column {
        anchors.left: mark.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        K.StyledText {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 15
            font.weight: Font.Bold
            color: root.c.strong
        }
        K.StyledText {
            width: parent.width
            text: root.text
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 12
            color: root.c.weak
        }
    }

    K.StateLayer {
        radius: root.radius
        color: root.c.strong
        onClicked: root.open?.()
    }
}
