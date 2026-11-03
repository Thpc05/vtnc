.pragma library

// The Visualizer Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
// a music visualizer (2026-10-09; base/services/Cava.qml): collapses while nothing plays
var meta = {
    title: "Visualizer",
    icon: "visualizer",
    styles: [
        { id: "bars", title: "Bars" },
        { id: "dots", title: "Dots" },
        { id: "shapes", title: "Shapes" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["bars", "dots", "shapes"],
    defaults: { compact: "bars", expanded: "bars" }
};
