import QtQuick
import qs.kit as K

// A list's caption in a panel (2026-10-16): the name small and weak, a hairline to the right edge and
// an optional action at its end (rescan), spinning while `busy`.
Item {
    id: root

    property var look: null
    property string text
    property string actionIcon: ""
    property bool busy: false
    signal action

    readonly property PanelColors c: PanelColors {
        look: root.look
    }

    implicitHeight: 28

    K.StyledText {
        id: label
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.family: K.Kit.family
        font.variableAxes: K.Kit.axes
        font.pixelSize: 11
        font.weight: 600
        color: root.c.weak
    }
    Rectangle {
        anchors.left: label.right
        anchors.leftMargin: 8
        anchors.right: button.visible ? button.left : parent.right
        anchors.rightMargin: button.visible ? 4 : 0
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        color: root.c.faint
    }
    Item {
        id: button
        anchors.right: parent.right
        // the glyph's edge on the content's edge
        anchors.rightMargin: -6
        anchors.verticalCenter: parent.verticalCenter
        visible: root.actionIcon !== ""
        width: 28
        height: 28

        K.StateLayer {
            radius: width / 2
            color: root.c.strong
            onClicked: root.action()
        }
        K.MaterialIcon {
            id: spin
            anchors.centerIn: parent
            text: root.actionIcon
            size: 16
            color: root.c.weak
            RotationAnimation on rotation {
                running: root.busy && K.Kit.anim.enabled
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1000
            }
            onVisibleChanged: rotation = 0
        }
    }
}
