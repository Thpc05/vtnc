.pragma library

// The Battery Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
// the Iwidget family (2026-10-11): upright / text / Default went (text alone = the `show` option)
var meta = {
    title: "Battery",
    icon: "batteryFull",
    styles: [
        { id: "shapes", title: "Shapes" },
        { id: "tones", title: "Two tones" },
        { id: "tone", title: "Tone" },
        { id: "ring", title: "Ring" },
        { id: "arc", title: "Arc" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["shapes", "tones", "tone", "ring", "arc"],
    defaults: { compact: "shapes", expanded: "shapes" }
};
