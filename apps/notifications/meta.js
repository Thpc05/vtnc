.pragma library

// The Notifications app (View.qml): the notification history.
// What the island, the launch targets and the Settings need to know about it;
// apps/index.js collects every meta.js.
var meta = {
    title: "Notifications",
    icon: "bell",
    // the view stays alive after the first close (its state survives), see R2 C6
    keepAlive: true,
    // Esc closes it
    closeOnEsc: true
};
