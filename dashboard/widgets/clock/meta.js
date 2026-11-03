.pragma library

// The Clock Dwidget (Widget.qml). It never expands.
var SIZES = ["3x2", "2x1", "3x1", "4x1", "2x2", "4x2", "3x3"];

var meta = {
    title: "Clock",
    icon: "clock",
    styles: [
        { id: "shapes", title: "Shapes", sizes: SIZES },
        { id: "tones", title: "Two tones", sizes: SIZES },
        { id: "tone", title: "Tone", sizes: SIZES }
    ],
    cards: ["shapes", "tones", "tone"],
    defaults: { idle: { style: "shapes", size: "3x2" }, options: {} }
};
