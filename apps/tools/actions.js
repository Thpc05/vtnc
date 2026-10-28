.pragma library

// The screen tools' actions (2026-10-11), shared by the Tools app (apps/tools/View.qml) and the Tools
// Qwidgets (one per action, dwidgets/quick/qwidgets.js), so their labels and icons never drift. `icon`
// is a property name of theme/Icons.qml; core/Actions.qml runs them (`runTool(id)`).
var SHOTS = [
    { id: "shot-region", icon: "selection", label: "Screenshot region", short: "Region" },
    { id: "shot-screen", icon: "monitor", label: "Screenshot screen", short: "Screen" }
];
// the record ones; while recording, the app shows STOP in their place (and a record Qwidget stops)
var RECORDS = [
    { id: "rec-region", icon: "screencast", label: "Record region", short: "Record region" },
    { id: "rec-screen", icon: "monitorPlay", label: "Record screen", short: "Record screen" },
    { id: "rec-audio", icon: "microphone", label: "Record with audio + mic", short: "Record + audio" }
];
var STOP = { id: "stop", icon: "stop", label: "Stop recording", variant: "error" };
var OTHERS = [
    { id: "picker", icon: "eyedropper", label: "Color picker", short: "Color picker" },
    { id: "ocr", icon: "textT", label: "Copy text from screen (OCR)", short: "OCR" }
];

function find(id) {
    var all = SHOTS.concat(RECORDS, [STOP], OTHERS);
    for (var i = 0; i < all.length; i++)
        if (all[i].id === id)
            return all[i];
    return null;
}

function isRecord(id) {
    return RECORDS.some(function (a) { return a.id === id; });
}
