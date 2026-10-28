import QtQuick
import qs.kit as K

// The colours of a panel, from the look of the Dwidget that opened it (`look.panel`: kind = shapes /
// tones / tone, pal, tone, overTone, strong, weak, faint), the Iwidget meanings (2026-10-16):
//  - shapes: the palette's roles (accent fills, `off` for the idle marks and buttons)
//  - tones / tone: everything in the tone (`accent`), weak and faint tints of it
QtObject {
    property var look: null

    readonly property var panel: look?.panel ?? ({})
    readonly property string kind: panel.kind ?? "shapes"
    readonly property bool shapes: kind === "shapes"
    // the opening Dwidget's Random shapes option (the marks)
    readonly property bool randomShapes: panel.randomShapes ?? true
    readonly property var pal: panel.pal ?? K.Kit.card
    readonly property color accent: shapes ? pal.accent : (panel.tone ?? pal.accent)
    readonly property color overAccent: shapes ? pal.overAccent : (panel.overTone ?? pal.overAccent)
    readonly property color strong: panel.strong ?? pal.over
    readonly property color weak: panel.weak ?? pal.overVariant
    readonly property color faint: panel.faint ?? pal.faint
    // an idle fill (a button that isn't the main one, a slider's track)
    // (Shapes: `high`, `off` is nearly the card's own colour)
    readonly property color off: shapes ? pal.high : Qt.alpha(accent, 0.14)
}
