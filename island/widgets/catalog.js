.pragma library

// Iwidget catalog: the single source of truth for the island widgets.
//  - styles: the looks a widget can take; the user picks one per mode (compact / expanded),
//    or "hidden" (not shown in that mode)
//  - defaults: the factory choice per mode (also used to migrate the old show/hidden model)
//  - card variants (2026-10-09): a style with a card is its own style, `{ id: "<base>Card", group:
//    "<base>", card: true }` (cards() adds them); no card is the parent and the default. The frame
//    (island/IwidgetFrame.qml) draws the card (Kit.islandCard, Island → General → Card colour) and the
//    widget only gets the base style.
// Used by core/WidgetRegistry.qml (UI), core/StateMerge.js (validation) and island/WidgetSlot.qml.

var HIDDEN = "hidden";

// `styles` plus a Card variant after each style named in `withCard`
function cards(styles, withCard) {
    var out = [];
    styles.forEach(function (s) {
        out.push(s);
        if (withCard.indexOf(s.id) >= 0)
            out.push({ id: s.id + "Card", title: "Card", group: s.id, card: true });
    });
    return out;
}

var WIDGETS = {
    workspaces: {
        title: "Workspaces",
        icon: "squaresFour",
        styles: cards([
            { id: "tones", title: "Two tones" },
            { id: "tone", title: "Tone" },
            { id: "pagination", title: "Pagination" }
        ], ["tones", "tone", "pagination"]),
        defaults: { compact: "tones", expanded: "tones" }
    },
    clock: {
        title: "Clock",
        icon: "clock",
        styles: cards([{ id: "time", title: "Time" }], ["time"]),
        defaults: { compact: "time", expanded: "time" }
    },
    // split from the clock (2026-10-08): each styled on its own (island.clock / island.date)
    date: {
        title: "Date",
        icon: "calendarBlank",
        styles: cards([{ id: "default", title: "Date" }], ["default"]),
        defaults: { compact: "default", expanded: "default" }
    },
    media: {
        title: "Media",
        icon: "player",
        // Controls became an option of every style (2026-10-15: island.media.<mode>.controls)
        styles: cards([
            { id: "default", title: "Default" },
            { id: "disc", title: "Disc" },
            { id: "tones", title: "Two tones" }
        ], ["default", "disc", "tones"]),
        defaults: { compact: "default", expanded: "default" }
    },
    recording: {
        title: "Recording",
        icon: "record",
        styles: [
            { id: "dot", title: "Dot" },
            { id: "pill", title: "Pill" },
            { id: "stop", title: "Stop button" }
        ],
        defaults: { compact: "dot", expanded: "dot" }
    },
    tray: {
        title: "Tray",
        icon: "dotsNine",
        // Compact became an option of both (2026-10-11: island.tray.<mode>.fold)
        styles: cards([
            { id: "icons", title: "Icons" },
            { id: "tint", title: "Tint" }
        ], ["icons", "tint"]),
        defaults: { compact: "icons", expanded: "icons" }
    },
    volume: {
        title: "Volume",
        icon: "speakerHigh",
        // one style since 2026-10-11 (user): the pill went, and the icon and the percent are options per
        // island mode (island.volume.<mode>.icon / percent); Icon + slider / Slider migrate
        styles: cards([
            { id: "slider", title: "Slider" }
        ], ["slider"]),
        defaults: { compact: "slider", expanded: "slider" }
    },
    battery: {
        title: "Battery",
        icon: "batteryFull",
        // the Iwidget family (2026-10-11): upright / text / Default went (text alone = the `show` option)
        styles: cards([
            { id: "shapes", title: "Shapes" },
            { id: "tones", title: "Two tones" },
            { id: "tone", title: "Tone" },
            { id: "ring", title: "Ring" },
            { id: "arc", title: "Arc" }
        ], ["shapes", "tones", "tone", "ring", "arc"]),
        defaults: { compact: "shapes", expanded: "shapes" }
    },
    notifications: {
        title: "Notifications",
        icon: "bell",
        styles: [
            { id: "bell", title: "Bell" },
            { id: "badge", title: "Bell + badge" },
            { id: "count", title: "Count" }
        ],
        defaults: { compact: "bell", expanded: "bell" }
    },
    // a music visualizer (2026-10-09; services/Cava.qml): collapses while nothing plays
    visualizer: {
        title: "Visualizer",
        icon: "visualizer",
        styles: cards([
            { id: "bars", title: "Bars" },
            { id: "dots", title: "Dots" },
            { id: "shapes", title: "Shapes" }
        ], ["bars", "dots", "shapes"]),
        defaults: { compact: "bars", expanded: "bars" }
    },
    // the focused window's title (2026-10-11): display only
    window: {
        title: "Active window",
        icon: "window",
        styles: cards([
            { id: "icon", title: "App icon" },
            { id: "tones", title: "Two tones" },
            { id: "tone", title: "Tone" },
            { id: "shapes", title: "Shapes" }
        ], ["icon", "tones", "tone", "shapes"]),
        defaults: { compact: "icon", expanded: "icon" }
    },
    // the apps' icons, pinned and open (2026-10-15): island.dock
    dock: {
        title: "Dock",
        icon: "dock",
        styles: cards([
            { id: "icons", title: "App icons" },
            { id: "tint", title: "Tint" }
        ], ["icons", "tint"]),
        defaults: { compact: "hidden", expanded: "icons" }
    },
    // the dashboard's Quick configs on the island (2026-10-09): the Qwidget models, toggle only
    // (island.quick.items)
    quick: {
        title: "Quick configs",
        icon: "gear",
        styles: cards([
            { id: "shapes", title: "Shapes" },
            { id: "tones", title: "Two tones" },
            { id: "tone", title: "Tone" }
        ], ["shapes", "tones", "tone"]),
        defaults: { compact: "shapes", expanded: "shapes" }
    }
};

function has(id) {
    return WIDGETS.hasOwnProperty(id);
}

// is `style` a valid choice for widget `id` ("hidden" always is)
function validStyle(id, style) {
    if (!has(id))
        return false;
    if (style === HIDDEN)
        return true;
    return WIDGETS[id].styles.some(function (s) { return s.id === style; });
}

// the style entry of `style` (null when unknown)
function styleEntry(id, style) {
    if (!has(id))
        return null;
    return WIDGETS[id].styles.find(function (s) { return s.id === style; }) || null;
}

// what the widget itself renders: a card variant's parent
function baseStyle(id, style) {
    var s = styleEntry(id, style);
    return s && s.group ? s.group : style;
}

function isCard(id, style) {
    var s = styleEntry(id, style);
    return !!(s && s.card);
}

// the Card variant of a parent style ("" when it has none)
function cardVariant(id, base) {
    if (!has(id))
        return "";
    var v = WIDGETS[id].styles.find(function (s) { return s.group === base && s.card; });
    return v ? v.id : "";
}

// the styles the settings list (parents only)
function parents(id) {
    return has(id) ? WIDGETS[id].styles.filter(function (s) { return !s.group; }) : [];
}

function defaultStyle(id, mode) {
    return has(id) ? WIDGETS[id].defaults[mode] : HIDDEN;
}
