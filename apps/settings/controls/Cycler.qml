import QtQuick
import qs.components
import qs.theme
import qs.dwidgets
import qs.dwidgets.quick.panels
import qs.kit as K

// "‹ value ›" selector for lists too long for a Segmented. Scroll also cycles.
// options: [{ value, label }]
Rectangle {
    id: root

    property var options: []
    property var value

    signal selected(var value)

    // the apps' look (R1.5, 2026-10-17): the idle fill, strong text
    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }
    readonly property int currentIndex: Math.max(0, options.findIndex(o => o.value === value))

    function cycle(dir: int) {
        if (options.length === 0)
            return;
        selected(options[(currentIndex + dir + options.length) % options.length].value);
    }

    implicitWidth: 180
    implicitHeight: 30
    radius: height / 2
    color: c.off

    WheelHandler {
        onWheel: e => root.cycle(e.angleDelta.y > 0 ? -1 : 1)
    }

    IconButton {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        icon: Icons.caretLeft
        size: 16
        color: root.c.strong
        onClicked: root.cycle(-1)
    }

    CapText {
        anchors.centerIn: parent
        width: parent.width - 60
        text: root.options[root.currentIndex]?.label ?? ""
        family: K.Kit.family
        pixelSize: Tokens.font.small
        weight: 600
        color: root.c.strong
    }

    IconButton {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        icon: Icons.caretRight
        size: 16
        color: root.c.strong
        onClicked: root.cycle(1)
    }
}
