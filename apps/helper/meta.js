.pragma library

// The Helper app (View.qml): the shell's own help: tour, keybinds, IPC, about.
// What the island, the launch targets and the Settings need to know about it;
// apps/index.js collects every meta.js.
var meta = {
    title: "Helper",
    icon: "help",
    // the view stays alive after the first close (its state survives), see R2 C6
    keepAlive: true,
    // Esc closes it
    closeOnEsc: true
};
