.pragma library

// The Active window Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
// the focused window's title (2026-10-11): display only
var meta = {
    title: "Active window",
    icon: "window",
    styles: [
        { id: "icon", title: "App icon" },
        { id: "tones", title: "Two tones" },
        { id: "tone", title: "Tone" },
        { id: "shapes", title: "Shapes" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["icon", "tones", "tone", "shapes"],
    defaults: { compact: "icon", expanded: "icon" }
};
