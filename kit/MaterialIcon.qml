import QtQuick
import qs.core
import qs.theme

// A Material Symbols Rounded icon by name (the M3 icon set), with its variable axes set as M3 asks:
//  - FILL 0 → 1 for the selected / on state
//  - GRAD -25 for light icons on dark (it thins them to read like dark-on-light ones), 0 in light
//  - wght 400 (M3's default weight)
//  - opsz = the size it's drawn at (20…48): the glyph's detail and stroke fit that size
// `size` (px) sets the size; else `fontStyle` (a Kit.font.icon.*).
// skip_previous / skip_next are drawn 1 px higher than the other glyphs in their box (measured at 12–24 px,
// 2026-10-15): they're lowered by that (an even ink height ends centred, an odd one half a pixel low
// instead of high). Place icons on whole pixels, as usual.
Text {
    id: root

    property real fill
    property int grade: Store.theme.light ? 0 : -25
    property int weight: 400
    property font fontStyle: Kit.font.icon.small
    // px; 0 = fontStyle's
    property real size: 0

    // (≥ 1: fontStyle can be unset while the item is torn down)
    readonly property real pixelSize: Math.max(1, size > 0 ? size : (fontStyle?.pointSize ?? 0) * 4 / 3)

    renderType: Tokens.font.renderType
    textFormat: Text.PlainText
    color: Colors.overSurface
    font.family: Kit.iconFamily
    font.pointSize: pixelSize * 3 / 4
    font.variableAxes: ({
            "FILL": Number(fill.toFixed(1)),
            "GRAD": grade,
            "wght": weight,
            "opsz": Math.max(20, Math.min(48, Math.round(pixelSize)))
        })

    Behavior on color {
        CAnim {}
    }

    readonly property bool lowered: text === "skip_previous" || text === "skip_next"
    transform: Translate {
        y: root.lowered ? 1 : 0
    }
}
