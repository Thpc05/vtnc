import QtQuick
import qs.dwidgets.quick.panels
import qs.kit as K

// The card at the top of every Helper tab (2026-10-17, user): what the tab is and how it works. Its
// symbol on an M3 shape (Shapes) or a tinted square (the tones), the title and a few lines of text; on
// the container (Shapes), a tint (Two tones) or a hairline frame (Tone).
Rectangle {
    id: root

    property string icon
    property string title
    property string text
    property string shape: "cookie7"
    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }

    // at least two lines of text: the search and the list don't jump between tabs
    implicitHeight: Math.max(104, column.implicitHeight + 32)
    radius: K.Kit.rounding.extraLarge
    color: c.shapes ? K.Kit.expressive.container : c.kind === "tones" ? Qt.tint(K.Kit.expressive.container, Qt.alpha(c.accent, K.Kit.expressive.light ? 0.14 : 0.1)) : "transparent"
    border.width: c.kind === "tone" ? 1 : 0
    border.color: Qt.alpha(c.accent, 0.3)

    Item {
        id: mark
        x: 20
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        height: 56

        K.M3Shape {
            anchors.fill: parent
            visible: root.c.shapes
            shape: root.shape
            samples: 72
            color: root.c.accent
        }
        Rectangle {
            anchors.fill: parent
            visible: !root.c.shapes
            radius: 16
            color: root.c.kind === "tones" ? root.c.accent : Qt.alpha(root.c.accent, 0.12)
        }
        K.MaterialIcon {
            anchors.centerIn: parent
            text: root.icon
            size: 26
            fill: 1
            color: root.c.kind === "tone" ? root.c.accent : root.c.overAccent
        }
    }

    Column {
        id: column
        anchors.left: mark.right
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        K.StyledText {
            width: parent.width
            text: root.title
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 18
            font.weight: Font.Bold
            color: root.c.strong
        }
        K.StyledText {
            width: parent.width
            text: root.text
            wrapMode: Text.Wrap
            textFormat: Text.StyledText
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 13
            lineHeight: 1.15
            color: root.c.weak
        }
    }
}
