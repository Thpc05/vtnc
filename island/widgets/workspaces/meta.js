.pragma library

// The Workspaces Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
var meta = {
    title: "Workspaces",
    icon: "squaresFour",
    styles: [
        { id: "tones", title: "Two tones" },
        { id: "tone", title: "Tone" },
        { id: "pagination", title: "Pagination" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["tones", "tone", "pagination"],
    defaults: { compact: "tones", expanded: "tones" }
};
