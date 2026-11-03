.pragma library

// The Recording Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
var meta = {
    title: "Recording",
    icon: "record",
    styles: [
        { id: "dot", title: "Dot" },
        { id: "pill", title: "Pill" },
        { id: "stop", title: "Stop button" }
    ],
    cards: [],
    defaults: { compact: "dot", expanded: "dot" }
};
