import QtQuick
import qs.core
import qs.theme

// An icon from theme/Icons.qml: a Material Symbols Rounded name, drawn with the M3 axes as
// kit/MaterialIcon does (FILL 0 → 1 for on, GRAD -25 on dark, wght 400, opsz = the size).
// Brand icons (Nerd Font rich text) pass through. Icon { icon: Icons.lock; size: 16 }
// A name may end in "@<degrees>" to turn the glyph (e.g. "pen_size_5@45": a diagonal stroke made
// horizontal), about its centre and apart from the item's own `rotation`.
Text {
    id: root

    property string icon: ""
    property int size: Tokens.font.large
    property real fill: 0
    property int weight: 400

    readonly property bool rich: icon.startsWith("<")
    readonly property int at: rich ? -1 : icon.lastIndexOf("@")
    readonly property real turn: at > 0 ? (parseFloat(icon.slice(at + 1)) || 0) : 0

    text: at > 0 ? icon.slice(0, at) : icon
    textFormat: rich ? Text.RichText : Text.PlainText
    transform: Rotation {
        origin.x: root.width / 2
        origin.y: root.height / 2
        angle: root.turn
    }
    color: Colors.overBackground
    font.family: Icons.font
    font.pixelSize: size
    font.variableAxes: ({
            "FILL": Number(fill.toFixed(1)),
            "GRAD": Store.theme.light ? 0 : -25,
            "wght": root.weight,
            "opsz": Math.max(20, Math.min(48, size))
        })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Tokens.font.renderType
}
