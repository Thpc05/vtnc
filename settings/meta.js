.pragma library

// The Settings app (View.qml): the shell's own settings, with the presets.
// What the island, the launch targets and the Settings need to know about it;
// apps/index.js collects every meta.js.
var meta = {
    title: "Settings",
    icon: "gear",
    // its launch target "vtnc:settings" (base/services/launch.js), with the name and icon
    // the pickers show
    launch: { title: "Settings", icon: "gear" },
    // the view stays alive after the first close (its state survives), see R2 C6
    keepAlive: true,
    // Esc closes it
    closeOnEsc: true
};
