.pragma library

// The Tools app (View.qml): the screen tools: shot, recording, picker, OCR.
// What the island, the launch targets and the Settings need to know about it;
// apps/index.js collects every meta.js.
var meta = {
    title: "Tools",
    icon: "camera",
    // its launch target "vtnc:tools" (base/services/launch.js), with the name and icon
    // the pickers show
    launch: { title: "Tools", icon: "camera" },
    // the view stays alive after the first close (its state survives), see R2 C6
    keepAlive: true,
    // Esc closes it
    closeOnEsc: true
};
