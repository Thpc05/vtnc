import QtQuick
import qs.dwidgets.quick.panels
import qs.kit as K

// A key (or a mouse button) as a small cap, in the apps' look: Shapes an idle fill, Two tones a tint,
// Tone an outline.
Rectangle {
    id: root

    property string text
    required property PanelColors c
    // on the current row (Two tones: its tint would swallow the cap's: an outline too)
    property bool current: false

    implicitWidth: Math.max(height, label.implicitWidth + 12)
    implicitHeight: 22
    radius: 6
    color: c.kind === "tone" ? "transparent" : c.off
    border.width: c.kind === "tone" || (current && c.kind === "tones") ? 1 : 0
    border.color: Qt.alpha(c.accent, 0.45)

    K.StyledText {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.family: K.Kit.family
        font.variableAxes: K.Kit.axes
        font.pixelSize: 11
        font.weight: 600
        color: root.c.shapes ? root.c.strong : root.c.accent
    }
}
