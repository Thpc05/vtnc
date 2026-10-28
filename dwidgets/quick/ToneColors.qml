import QtQuick
import qs.theme
import qs.kit as K

// The colour of the Two tones / Tone looks (2026-10-11): a role (primary / surface / variant / secondary
// / tertiary, as the tray's tint) resolved against the palette under it (`pal`: a card's or the bare
// page's), and its ink for what sits on it. Quick configs (Dwidget and Iwidget) and the toggles.
QtObject {
    property var pal: K.Kit.bare
    property string role: "primary"

    readonly property color tone: {
        switch (role) {
        case "surface":
            return pal.over;
        case "variant":
            return pal.overVariant;
        case "secondary":
            return Colors.secondary;
        case "tertiary":
            return Colors.tertiary;
        default:
            return pal.accent;
        }
    }
    readonly property color overTone: role === "secondary" ? Colors.overSecondary : role === "tertiary" ? Colors.overTertiary : role === "surface" || role === "variant" ? Colors.surface : pal.overAccent
}
