.pragma library

// The Tray Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
// Compact became an option of both (2026-10-11: island.tray.<mode>.fold)
var meta = {
    title: "Tray",
    icon: "dotsNine",
    styles: [
        { id: "icons", title: "Icons" },
        { id: "tint", title: "Tint" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["icons", "tint"],
    defaults: { compact: "icons", expanded: "icons" }
};
