.pragma library

// The Dashboard app (View.qml): the grid of Dwidgets.
// What the island, the launch targets and the Settings need to know about it;
// apps/index.js collects every meta.js.
var meta = {
    title: "Dashboard",
    icon: "squaresFour",
    // its launch target "vtnc:dashboard" (base/services/launch.js), with the name and icon
    // the pickers show
    launch: { title: "Dashboard", icon: "squaresFour" },
    // the view stays alive after the first close (its state survives), see R2 C6
    keepAlive: true,
    // Esc closes it
    closeOnEsc: true
};
