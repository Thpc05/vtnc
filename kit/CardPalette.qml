import QtQuick
import qs.theme

// A card's palette for a `kind` (Kit.card = Kit.islandCard: the Dwidgets' and Iwidgets' cards,
// `theme.card`): neutral (surfaceContainer) · container (primaryContainer) · tinted
// (surfaceContainer with a primary tint) · primary (primary, the accent turned onPrimary). The roles
// are Kit.bare's: fill · over / overVariant · accent / overAccent · off / high · selected /
// overSelected · tonal / overTonal · track · weak / faint.
QtObject {
    property string kind: "neutral"

    readonly property bool inverse: kind === "primary"
    readonly property color fill: Colors.layer(kind === "container" ? Colors.primaryContainer : kind === "primary" ? Colors.primary : kind === "tinted" ? Qt.tint(Colors.surfaceContainer, Qt.alpha(Colors.primary, 0.14)) : Colors.surfaceContainer, 1)
    readonly property color over: kind === "container" ? Colors.overPrimaryContainer : inverse ? Colors.overPrimary : Colors.overSurface
    readonly property color overVariant: kind === "container" || inverse ? Qt.alpha(over, 0.75) : Colors.overSurfaceVariant
    readonly property color accent: inverse ? Colors.overPrimary : Colors.primary
    readonly property color overAccent: inverse ? Colors.primary : Colors.overPrimary
    // neutral: the kit's ladder (Kit.expressive off / high); the others: steps tinted towards the accent
    readonly property color off: kind === "neutral" ? Colors.layer(Colors.surfaceContainerHigh, 2) : Colors.layer(Qt.tint(fill, Qt.alpha(inverse ? Colors.overPrimary : Colors.primary, 0.14)), 2)
    readonly property color high: kind === "neutral" ? Colors.layer(Colors.surfaceContainerHighest, 2) : Colors.layer(Qt.tint(fill, Qt.alpha(inverse ? Colors.overPrimary : Colors.primary, 0.26)), 2)
    readonly property color selected: kind === "container" ? high : Colors.primaryContainer
    readonly property color overSelected: kind === "container" ? over : Colors.overPrimaryContainer
    readonly property color tonal: kind === "neutral" ? Colors.secondaryContainer : high
    readonly property color overTonal: kind === "neutral" ? Colors.overSecondaryContainer : over
    readonly property color track: kind === "neutral" ? Colors.secondaryContainer : Qt.alpha(accent, 0.25)
    readonly property color weak: Qt.alpha(accent, 0.55)
    readonly property color faint: Qt.alpha(accent, 0.2)
}
