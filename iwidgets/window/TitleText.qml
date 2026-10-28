import QtQuick
import qs.kit as K

// A line of the active window Iwidget: two texts that cross-fade when `text` changes (the old one fades
// out as the new one fades in), elided to `maxWidth`. `textWidth` is its width, worked out from the
// text (not from the Text items: they lag a frame behind, and the slot animates to it). The caps are
// centred, not the line box (it sat ~1.5 px high; see iwidgets/clock/TextPill.qml).
Item {
    id: root

    property string text
    property real maxWidth: 200
    property color color
    property int weight: 600
    property int pixelSize: 12

    readonly property real textWidth: text === "" ? 0 : Math.min(Math.ceil(full.advanceWidth), Math.floor(maxWidth))

    implicitWidth: textWidth
    implicitHeight: 20

    // which of the two shows the current text
    property bool first: true
    onTextChanged: {
        (first ? two : one).text = text;
        first = !first;
    }
    Component.onCompleted: one.text = text

    TextMetrics {
        id: full
        font: one.font
        text: root.text
    }
    TextMetrics {
        id: caps
        font: one.font
        text: "H0"
    }
    FontMetrics {
        id: metrics
        font: one.font
    }

    component Line: Text {
        y: Math.round((root.height - caps.tightBoundingRect.height) / 2 - (metrics.ascent + caps.tightBoundingRect.y))
        // each at its own text's width: the old one fading out isn't re-elided to the new one's
        width: Math.min(Math.ceil(implicitWidth), Math.floor(root.maxWidth))
        elide: Text.ElideRight
        font.family: K.Kit.family
        font.variableAxes: K.Kit.axes
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        color: root.color
        Behavior on opacity {
            K.Anim {
                type: K.Anim.DefaultEffects
            }
        }
        Behavior on color {
            K.CAnim {}
        }
    }

    Line {
        id: one
        opacity: root.first ? 1 : 0
    }
    Line {
        id: two
        opacity: root.first ? 0 : 1
    }
}
