import QtQuick
import qs.base.theme

// A card's palette for a `kind` (Kit.card: the Dwidgets' and Iwidgets' cards, `theme.card`; Kit.cardFor:
// a card's own colour, 2026-10-29):
//   neutral (surfaceContainer) · tinted (surfaceContainer with a primary tint)
//   container / secondaryContainer / tertiaryContainer (that role's container)
//   primary / secondary / tertiary (the role itself, the accent turned roleInk)
// The roles are Kit.bare's: fill · over / overVariant · accent / overAccent · off / high · selected /
// overSelected · tonal / overTonal · track · weak / faint.
QtObject {
    property string kind: "neutral"

    // the colour role behind the kind, and whether it's its container or the role itself
    readonly property string role: kind.startsWith("secondary") ? "secondary" : kind.startsWith("tertiary") ? "tertiary" : "primary"
    readonly property bool isContainer: kind === "container" || kind === "secondaryContainer" || kind === "tertiaryContainer"
    readonly property bool inverse: kind === "primary" || kind === "secondary" || kind === "tertiary"
    readonly property string roleName: role[0].toUpperCase() + role.slice(1)
    readonly property color roleColor: Colors[role]
    readonly property color roleInk: Colors["over" + roleName]

    readonly property color fill: Colors.layer(isContainer ? Colors[role + "Container"] : inverse ? roleColor : kind === "tinted" ? Qt.tint(Colors.surfaceContainer, Qt.alpha(Colors.primary, 0.14)) : Colors.surfaceContainer, 1)
    readonly property color over: isContainer ? Colors["over" + roleName + "Container"] : inverse ? roleInk : Colors.overSurface
    readonly property color overVariant: isContainer || inverse ? Qt.alpha(over, 0.75) : Colors.overSurfaceVariant
    readonly property color accent: inverse ? roleInk : roleColor
    readonly property color overAccent: inverse ? roleColor : roleInk
    // neutral: the kit's ladder (Kit.expressive off / high); the others: steps tinted towards the accent
    readonly property color off: kind === "neutral" ? Colors.layer(Colors.surfaceContainerHigh, 2) : Colors.layer(Qt.tint(fill, Qt.alpha(accent, 0.14)), 2)
    readonly property color high: kind === "neutral" ? Colors.layer(Colors.surfaceContainerHighest, 2) : Colors.layer(Qt.tint(fill, Qt.alpha(accent, 0.26)), 2)
    readonly property color selected: isContainer ? high : Colors.primaryContainer
    readonly property color overSelected: isContainer ? over : Colors.overPrimaryContainer
    readonly property color tonal: kind === "neutral" ? Colors.secondaryContainer : high
    readonly property color overTonal: kind === "neutral" ? Colors.overSecondaryContainer : over
    readonly property color track: kind === "neutral" ? Colors.secondaryContainer : Qt.alpha(accent, 0.25)
    readonly property color weak: Qt.alpha(accent, 0.55)
    readonly property color faint: Qt.alpha(accent, 0.2)
}
