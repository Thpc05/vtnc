.pragma library

// The summary Dwidgets (Widget.qml, 2026-10-17, user): the apps' summaries — Notifications,
// Clipboard, Notes and (2026-10-27) Dino run. 1x1 / 2x1 / 1x2 a badge (the count), 2x2 and up a list
// of the latest items; they never expand (a click acts or opens the app). Helper gets none.

// (2026-10-27, user: more rectangles, 2 and 3 thick; wide lists flow into columns)
var SIZES = ["3x3", "1x1", "2x1", "1x2", "2x2", "3x2", "4x2", "5x2", "6x2", "7x2", "8x2", "2x3", "4x3", "5x3", "6x3", "7x3",
    "2x4", "2x5", "2x6", "2x7", "2x8", "3x4", "3x5", "3x6", "4x4"];

function summary(title, icon) {
    return {
        title: title,
        icon: icon,
        styles: [
            { id: "shapes", title: "Shapes", sizes: SIZES },
            { id: "tones", title: "Two tones", sizes: SIZES },
            { id: "tone", title: "Tone", sizes: SIZES }
        ],
        cards: ["shapes", "tones", "tone"],
        defaults: { idle: { style: "shapes", size: "3x3" }, options: {} }
    };
}

// one folder, several Dwidgets: the index lists each id and loads this folder's Widget.qml for it
var metas = {
    notifications: summary("Notifications", "bell"),
    clipboard: summary("Clipboard", "clipboard"),
    notes: summary("Notes", "notes"),
    dino: summary("Dino run", "dino")
};
