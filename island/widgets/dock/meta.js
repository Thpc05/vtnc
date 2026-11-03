.pragma library

// The Dock Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
// the apps' icons, pinned and open (2026-10-15): island.dock
var meta = {
    title: "Dock",
    icon: "dock",
    styles: [
        { id: "icons", title: "App icons" },
        { id: "tint", title: "Tint" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["icons", "tint"],
    defaults: { compact: "hidden", expanded: "icons" }
};
