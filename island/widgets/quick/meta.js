.pragma library

// The Quick configs Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
// the dashboard's Quick configs on the island (2026-10-09): the Qwidget models, toggle only
// (island.quick.items)
var meta = {
    title: "Quick configs",
    icon: "gear",
    styles: [
        { id: "shapes", title: "Shapes" },
        { id: "tones", title: "Two tones" },
        { id: "tone", title: "Tone" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["shapes", "tones", "tone"],
    defaults: { compact: "shapes", expanded: "shapes" }
};
