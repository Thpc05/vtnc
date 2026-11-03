.pragma library

// The Clipboard app (View.qml): the clipboard history (cliphist).
// What the island, the launch targets and the Settings need to know about it;
// apps/index.js collects every meta.js.
var meta = {
    title: "Clipboard",
    icon: "clipboard",
    // the view stays alive after the first close (its state survives), see R2 C6
    keepAlive: true,
    // Esc closes it
    closeOnEsc: true
};
