.pragma library

// The Volume Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
// one style since 2026-10-11 (user): the pill went, and the icon and the percent are options per
// island mode (island.volume.<mode>.icon / percent); Icon + slider / Slider migrate
var meta = {
    title: "Volume",
    icon: "speakerHigh",
    styles: [
        { id: "slider", title: "Slider" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["slider"],
    defaults: { compact: "slider", expanded: "slider" }
};
