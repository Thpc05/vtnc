.pragma library

// Swidget catalog: the sliders of the Sliders Dwidget (see ../README.md, "Sliders"), like the
// Qwidgets of Quick configs.
//  - title / icon: for the settings chips (icon = a property name of theme/Icons.qml); the live
//    level comes from the model in swidgets/<Id>.qml
// The entry's options.items is the ordered list of the Swidgets shown.

var SWIDGETS = {
    volume: { title: "Volume", icon: "speakerHigh" },
    mic: { title: "Microphone", icon: "mic" },
    brightness: { title: "Brightness", icon: "sun" },
    nightLight: { title: "Night light", icon: "nightLight" }
};

var DEFAULT_ITEMS = ["volume", "brightness"];

function has(id) {
    return SWIDGETS.hasOwnProperty(id);
}

// `v` as a plain array when it is a list (a JS array, or the array-like a model makes), else null
function asArray(v) {
    if (Array.isArray(v))
        return v;
    if (v && typeof v === "object" && typeof v.length === "number")
        return Array.prototype.slice.call(v);
    return null;
}

// the valid Swidget ids of options.items, in order, without duplicates (the defaults when missing)
function items(options) {
    var list = (options && asArray(options.items)) || DEFAULT_ITEMS;
    var seen = {};
    return list.filter(function (id) {
        if (typeof id !== "string" || !has(id) || seen[id])
            return false;
        seen[id] = true;
        return true;
    });
}

// the Swidgets not in `shown`, in catalog order
function available(shown) {
    return Object.keys(SWIDGETS).filter(function (id) {
        return shown.indexOf(id) < 0;
    });
}
