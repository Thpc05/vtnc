.pragma library

// The launcher app, "Apps" on screen (View.qml): search and open desktop entries.
// What the island, the launch targets and the Settings need to know about it;
// apps/index.js collects every meta.js.
var meta = {
    title: "Apps",
    icon: "apps",
    // its launch target "vtnc:launcher" (base/services/launch.js), with the name and icon
    // the pickers show
    launch: { title: "Launcher", icon: "magnifyingGlass" },
    // the view stays alive after the first close (its state survives), see R2 C6
    keepAlive: true,
    // Esc closes it
    closeOnEsc: true
};
