.pragma library

// The Visualizer Dwidget (Widget.qml): the music visualizer (base/services/Cava.qml). It never expands.
var SIZES = ["4x2", "2x1", "3x1", "4x1", "6x1", "2x2", "3x2", "6x2"];

var meta = {
    title: "Visualizer",
    icon: "visualizer",
    styles: [
        { id: "bars", title: "Bars", sizes: SIZES },
        { id: "dots", title: "Dots", sizes: SIZES },
        { id: "shapes", title: "Shapes", sizes: SIZES }
    ],
    cards: ["bars", "dots", "shapes"],
    defaults: { idle: { style: "bars", size: "4x2" }, options: {} }
};
