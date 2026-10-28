import QtQuick
import qs.dwidgets.quick
import qs.kit as K

// The top of a panel (2026-10-16, user's pick "hero do estado"): what's on now, big (the connected
// network or device, the profile, the temperature, the output), its mark in the Qwidgets' language
// (QMark: Shapes an accent circle or M3 shape, Two tones a square in the tone, Tone the icon alone),
// its name and state, and its actions as one connected group. Nothing on: the mark idle and a hint.
// The mark and the name are the Qwidget's switch (2026-10-27, user: no switch in a header): a click
// toggles it, when `qwidget` is one that switches.
Item {
    id: root

    property var look: null
    // the panel's Qwidget: a click on the mark or the name toggles it (when it's `switchable`)
    property QtObject qwidget: null
    readonly property bool toggles: qwidget !== null && (qwidget.switchable ?? true) && !(qwidget.opensPanel ?? false)
    property string symbol
    property string title
    property string subtitle
    // something is on (the mark's "on")
    property bool active: true
    // [{ text, icon?, primary?, run }] (ActionGroup)
    property var actions: []
    // extra content under the name (a slider…), its height
    default property alias extra: extraBox.data
    property real extraHeight: 0

    readonly property PanelColors c: PanelColors {
        look: root.look
    }
    // 44; a compact hero (the Mixer's wide panel) 32
    property int markSize: 44

    implicitHeight: markSize + (extraHeight > 0 ? 8 + extraHeight : 0) + (actions.length > 0 ? 10 + group.implicitHeight : 0)

    QtObject {
        id: mark
        property bool active: root.active
        property string symbol: root.symbol
        property bool available: true
    }
    QMark {
        id: markItem
        width: root.markSize
        height: root.markSize
        q: mark
        look: root.c.kind
        pal: root.c.pal
        tone: root.c.accent
        overTone: root.c.overAccent
        shapesRandom: root.c.randomShapes
        iconSize: 2 * Math.round(root.markSize / 4)
        weight: root.c.kind === "tones" ? 600 : 400
    }
    Column {
        anchors.left: markItem.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.verticalCenter: markItem.verticalCenter
        spacing: 1

        K.StyledText {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            // a long name shrinks (down to 14 px, above the subtitle) before it elides
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 14
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: root.markSize >= 44 ? 17 : 14
            font.weight: Font.Bold
            color: root.c.shapes || root.active ? root.c.strong : root.c.weak
        }
        K.StyledText {
            width: parent.width
            visible: text !== ""
            text: root.subtitle
            elide: Text.ElideRight
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 12
            color: root.c.weak
        }
    }
    // the switch: the mark and the name
    K.StateLayer {
        anchors.fill: undefined
        x: -4
        y: -2
        width: root.width + 8
        height: root.markSize + 4
        visible: root.toggles
        radius: Math.min(height / 2, K.Kit.rounding.large)
        color: root.c.strong
        onClicked: root.qwidget.toggle()
    }
    Item {
        id: extraBox
        y: root.markSize + 8
        width: root.width
        height: root.extraHeight
        visible: root.extraHeight > 0
    }
    ActionGroup {
        id: group
        y: root.markSize + (root.extraHeight > 0 ? 8 + root.extraHeight : 0) + 10
        width: root.width
        visible: root.actions.length > 0
        look: root.look
        actions: root.actions
    }
}
