.pragma library

// The Calendar Dwidget (Widget.qml, CalendarView.qml): the Iwidget family (2026-10-11, redone from
// scratch): shapes, two tones, tone, each also on the card; the size picks the layout.

// (2026-10-11) a month (3x3 and up), a week in a row (4x1…7x1), today (1x1, 2x1, 1x2, 2x2)
var SIZES = ["3x3", "4x3", "3x4", "4x4", "5x4", "4x1", "5x1", "6x1", "7x1", "1x1", "2x1", "1x2", "2x2"];

var meta = {
    title: "Calendar",
    icon: "calendarBlank",
    styles: [
        { id: "shapes", title: "Shapes", sizes: SIZES },
        { id: "tones", title: "Two tones", sizes: SIZES },
        { id: "tone", title: "Tone", sizes: SIZES }
    ],
    cards: ["shapes", "tones", "tone"],
    defaults: { idle: { style: "shapes", size: "3x3" }, options: {} },
    // the earlier Expressive was two tones
    renames: { expressiveNoCard: "tones", expressive: "tonesCard" }
};
