import QtQuick
import qs.theme
import qs.dwidgets.quick.panels
import qs.kit as K

// A small labelled button (the kit's TextButton, caelestia's): tonal; `accent` = filled primary,
// `danger` = errorContainer. Disabled (`enabled: false`): M3's disabled colors.
K.TextButton {
    id: button

    property bool accent: false
    property bool danger: false

    // the apps' look (R1.5, 2026-10-17): the idle fill, strong text
    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }

    type: accent ? K.ButtonBase.Filled : K.ButtonBase.Tonal
    disabled: !enabled
    // the settings' compact size (Tokens px), in the kit's font
    font: Qt.font({
        family: K.Kit.family,
        pixelSize: Tokens.font.small,
        weight: accent ? Font.Bold : Font.Medium,
        variableAxes: K.Kit.axes
    })
    // the inline controls' height
    implicitHeight: 30

    // the apps' look: the idle fill with strong text, `accent` the accent (Tone: a tint), `danger` the error
    inactiveColour: danger ? Colors.errorContainer : accent ? (c.kind === "tone" ? Qt.alpha(c.accent, 0.28) : c.accent) : c.off
    inactiveOnColour: danger ? Colors.overErrorContainer : accent ? (c.kind === "tone" ? c.accent : c.overAccent) : c.strong
}
