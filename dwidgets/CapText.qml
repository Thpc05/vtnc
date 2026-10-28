import QtQuick
import qs.kit as K

// A Dwidget text (calendar, media) centred by its caps / digits, not its line box (that sat ~1.5 px high; the TextPill
// method, iwidgets/clock/TextPill.qml). Rubik by default (numbers); Google Sans Flex gets its ROND axis.
Item {
    id: root

    property string text
    property string family: K.Kit.clockFamily
    property int pixelSize: 12
    property int weight: 500
    property color color
    property int horizontalAlignment: Text.AlignHCenter

    // where the baseline falls (marks under the text hang from it)
    readonly property real baseY: label.y + metrics.ascent

    implicitWidth: Math.ceil(label.implicitWidth)
    implicitHeight: Math.ceil(caps.tightBoundingRect.height)

    TextMetrics {
        id: caps
        font: label.font
        text: "H0"
    }
    FontMetrics {
        id: metrics
        font: label.font
    }

    Text {
        id: label
        width: root.width
        y: Math.round((root.height - caps.tightBoundingRect.height) / 2 - (metrics.ascent + caps.tightBoundingRect.y))
        horizontalAlignment: root.horizontalAlignment
        elide: Text.ElideRight
        text: root.text
        font.family: root.family
        font.variableAxes: root.family === K.Kit.family ? K.Kit.axes : ({})
        font.pixelSize: root.pixelSize
        font.weight: Math.max(100, Math.min(900, root.weight))
        font.features: ({
                "tnum": 1
            })
        color: root.color
    }
}
