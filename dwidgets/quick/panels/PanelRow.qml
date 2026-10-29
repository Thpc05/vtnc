import QtQuick
import qs.dwidgets.quick
import qs.kit as K

// One row of a panel's list (networks, devices, profiles, outputs), compact and bare (2026-10-16, the
// "hero" panels): a small mark in the Qwidgets' language (QMark), the name, the state at the right
// (weak) and `trailing` marks (lock, battery). A click emits `clicked`; while `open` the default
// children show under it (a password field, an ActionGroup) on a faint fill.
Item {
    id: row

    property var look: null
    property bool current: false
    property bool open: false
    property bool usable: true
    property string icon
    property string title
    property string subtitle
    property real headHeight: 36
    default property alias actions: actionsBox.data
    property alias trailing: trailingRow.data
    signal clicked

    readonly property PanelColors c: PanelColors {
        look: row.look
    }
    // (the callers' old names)
    readonly property color weak: c.weak
    readonly property color accent: c.accent
    readonly property real radius: K.Kit.rounding.medium

    implicitHeight: headHeight + (open ? actionsBox.implicitHeight + 8 : 0)
    // open: scrolled into view once it has grown (the list's `positionViewAtIndex`)
    signal grown
    Timer {
        id: grownTimer
        interval: K.Kit.anim.durations.expressiveFastSpatial + 20
        onTriggered: row.grown()
    }
    onOpenChanged: if (open)
        grownTimer.restart()
    height: implicitHeight
    clip: true
    opacity: usable ? 1 : 0.5
    Behavior on implicitHeight {
        K.Anim {
            type: K.Anim.FastSpatial
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: row.open
        radius: row.radius
        color: row.c.faint
    }

    Item {
        id: head
        width: parent.width
        height: row.headHeight

        K.StateLayer {
            radius: row.radius
            color: row.c.strong
            disabled: !row.usable
            onClicked: row.clicked()
        }

        QtObject {
            id: markModel
            property bool active: row.current
            property string symbol: row.icon
            property bool available: true
        }
        QMark {
            id: mark
            // open: inset from the faint fill's edge
            x: row.open ? 6 : 0
            y: Math.round((parent.height - height) / 2)
            width: 28
            height: 28
            q: markModel
            look: row.c.kind
            pal: row.c.pal
            tone: row.c.accent
            overTone: row.c.overAccent
            shapesRandom: row.c.randomShapes
            iconSize: 16
        }
        K.StyledText {
            anchors.left: mark.right
            anchors.leftMargin: 10
            anchors.right: status.left
            anchors.rightMargin: status.width > 0 ? 6 : 0
            anchors.verticalCenter: parent.verticalCenter
            text: row.title
            elide: Text.ElideRight
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 13
            font.weight: row.current ? Font.Bold : Font.Medium
            // strong in every look (a weak list read washed out); the current one bold, its mark on
            color: row.c.strong
        }
        K.StyledText {
            id: status
            anchors.right: trailingRow.left
            anchors.rightMargin: trailingRow.width > 0 ? 6 : 0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, head.width * 0.3)
            text: row.subtitle
            elide: Text.ElideRight
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 11
            color: row.c.weak
        }
        Row {
            id: trailingRow
            anchors.right: parent.right
            anchors.rightMargin: row.open ? 4 : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
        }
    }

    Column {
        id: actionsBox
        x: 6
        y: row.headHeight + 2
        width: parent.width - 12
        spacing: 6
        visible: row.open
    }
}
