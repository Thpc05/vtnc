.pragma library

// The Clock Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
var meta = {
    title: "Clock",
    icon: "clock",
    styles: [
        { id: "time", title: "Time" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["time"],
    defaults: { compact: "time", expanded: "time" }
};
