.pragma library

// The Sliders Dwidget (Widget.qml): system levels, the Swidgets in options.items (swidgets.js),
// vertical side by side when the rect is at least as tall as wide, else stacked; Google's M3 sliders
// (flat or wavy). Every horizontal size has its vertical one (3x1 → 1x3).

var SIZES = ["4x1", "3x1", "5x1", "6x1", "3x2", "4x2", "2x2", "2x3", "2x4", "1x3", "1x4", "1x5", "1x6"];

var meta = {
    title: "Sliders",
    icon: "sliders",
    // the Iwidget family (2026-10-11)
    styles: [
        { id: "shapes", title: "Shapes", sizes: SIZES },
        { id: "tones", title: "Two tones", sizes: SIZES },
        { id: "tone", title: "Tone", sizes: SIZES }
    ],
    cards: ["shapes", "tones", "tone"],
    defaults: { idle: { style: "shapes", size: "4x1" }, options: {} },
    renames: { inset: "shapes", tonesNoCard: "tones", wavyNoCard: "tone", wavy: "toneCard" }
};
