.pragma library

// The Date Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
// split from the clock (2026-10-08): each styled on its own (island.clock / island.date)
var meta = {
    title: "Date",
    icon: "calendarBlank",
    styles: [
        { id: "default", title: "Date" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["default"],
    defaults: { compact: "default", expanded: "default" }
};
