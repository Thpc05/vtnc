.pragma library

// The Image Dwidget (Widget.qml): an image or GIF from the system.

// squares, then (2026-10-27, user) rectangles both ways, up to 6x4 / 4x6
var SIZES = ["2x2", "1x1", "3x3", "4x4", "5x5", "6x6", "2x1", "1x2", "3x1", "1x3", "3x2", "2x3", "4x2", "2x4",
    "4x3", "3x4", "5x3", "3x5", "6x3", "3x6", "5x4", "4x5", "6x4", "4x6"];

var meta = {
    title: "Image",
    icon: "image",
    styles: [{ id: "image", title: "Image", sizes: SIZES }],
    cards: ["image"],
    defaults: { idle: { style: "image", size: "2x2" }, options: {} }
};
