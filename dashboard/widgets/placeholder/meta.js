.pragma library

// The Placeholder Dwidget (Widget.qml): shows its id / style / size. A debug widget, never offered in
// the Off area — only the demo layout uses it — for trying the layout engine and the expand modes.
var meta = {
    title: "Placeholder",
    icon: "squaresFour",
    debug: true,
    styles: [
        { id: "box", title: "Box", sizes: ["2x2", "1x1", "2x1", "3x2", "4x3"] },
        { id: "tall", title: "Tall", sizes: ["1x2", "1x3", "3x3"] }
    ],
    cards: [],
    defaults: { idle: { style: "box", size: "2x2" }, options: {} },
    expand: { size: "4x3", trigger: "click" }
};
