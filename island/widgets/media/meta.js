.pragma library

// The Media Iwidget (Widget.qml). What the island, the Settings and the state validation need to
// know about it; island/widgets/index.js collects every meta.js.
// Controls became an option of every style (2026-10-15: island.media.<mode>.controls)
var meta = {
    title: "Media",
    icon: "player",
    styles: [
        { id: "default", title: "Default" },
        { id: "disc", title: "Disc" },
        { id: "tones", title: "Two tones" }
    ],
    // a Card variant after each of these styles (island/IwidgetFrame.qml draws the card)
    cards: ["default", "disc", "tones"],
    defaults: { compact: "default", expanded: "default" }
};
