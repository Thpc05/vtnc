.pragma library

// The Quick configs Dwidget (Widget.qml): Qwidgets (qwidgets.js) in the Iwidget family (QuickView,
// QMark); the size arranges them (icons when short or narrow, else pills). Every horizontal size has
// its vertical one (4x1 → 1x4). It expands only to show the Mixer's panel (its click opens it); the
// other panels open in the toggle Dwidgets.

var SIZES = ["4x1", "2x1", "3x1", "5x1", "6x1", "7x1", "8x1", "2x2", "3x2", "4x2", "5x2", "6x2", "8x2", "3x3", "4x3", "4x4", "1x2", "1x3", "1x4", "1x5", "1x6", "2x3", "2x4", "2x5", "2x6"];

var meta = {
    title: "Quick configs",
    icon: "gear",
    // the Iwidget family (2026-10-11, redone from scratch in the island's language)
    styles: [
        { id: "shapes", title: "Shapes", sizes: SIZES },
        { id: "tones", title: "Two tones", sizes: SIZES },
        { id: "tone", title: "Tone", sizes: SIZES }
    ],
    cards: ["shapes", "tones", "tone"],
    defaults: { idle: { style: "shapes", size: "4x1" }, options: {} },
    // only to show the Mixer's panel (a click on the Mixer Qwidget): no event of its own
    expand: { size: "6x5", trigger: "none", panelOnly: true },
    renames: { shapesNoCard: "shapes", tonesNoCard: "tones" }
};
