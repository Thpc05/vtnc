.pragma library

// The Wallpapers app (View.qml): picks the wallpaper (awww) and the colours that follow it.
// What the island, the launch targets and the Settings need to know about it;
// apps/index.js collects every meta.js.
var meta = {
    title: "Wallpapers",
    icon: "image",
    // its launch target "vtnc:wallpaper" (base/services/launch.js), with the name and icon
    // the pickers show
    launch: { title: "Wallpapers", icon: "image" },
    // the view stays alive after the first close (its state survives), see R2 C6
    keepAlive: true,
    // Esc closes it
    closeOnEsc: true
};
