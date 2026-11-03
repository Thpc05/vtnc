.pragma library

// The Notifications Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
var meta = {
    title: "Notifications",
    icon: "bell",
    styles: [
        { id: "bell", title: "Bell" },
        { id: "badge", title: "Bell + badge" },
        { id: "count", title: "Count" }
    ],
    cards: [],
    defaults: { compact: "bell", expanded: "bell" }
};
