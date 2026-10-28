.pragma library

// Dwidget catalog: the single source of truth for the dashboard widgets (see README.md).
//  - styles: the looks a Dwidget can take, each with the sizes it allows ("WxH" in grid cells;
//    the first is the style's default). A style with `group` is a variant of that style (the
//    settings show a tree: the style, then its variants by their `variant` label)
//  - defaults: a new entry's look, idle { style, size }, and options
//    (a style with and without a card: the no-card one is the parent and the default — user, 2026-10-08)
//  - expand: { size, trigger } only for the Dwidgets that need to expand (the Wi-Fi / Bluetooth
//    toggles, for their lists): the size it grows to, in the same style, and the default event;
//    their entries may pick another (expandOn: click · doubleclick · hover · none). The others never
//    expand; other looks are styles.
//  - debug: true → never offered in the Off area (only the demo layout uses it)
//  - preview: false → the settings editor shows a simple box instead of the real Dwidget
// Used by core/DwidgetRegistry.qml (UI), core/StateMerge.js (validation) and apps/dashboard.

var MODES = ["over", "push", "takeover"];
// the Dwidgets' card colour (Kit.card)
var CARDS = ["neutral", "container", "tinted", "primary"];
var TRIGGERS = ["click", "doubleclick", "hover", "none"];

// the media's sizes (redone 2026-10-11): a strip (3x1…6x1), 2x2, the art at the left (3x2…6x2, 4x3,
// 5x3, 6x3), the art on top (3x3, 3x4, 4x4, 5x4)
var MEDIA_SIZES = ["4x2", "3x1", "4x1", "5x1", "6x1", "2x2", "3x2", "5x2", "6x2", "3x3", "4x3", "5x3", "6x3", "3x4", "4x4", "5x4"];

// the sliders' sizes (every style fits them)
var SLIDERS_SIZES = ["4x1", "3x1", "5x1", "6x1", "3x2", "4x2", "2x2", "2x3", "2x4", "1x3", "1x4", "1x5", "1x6"];

// Quick configs' sizes (every style fits them; redone 2026-10-11): a row of 2…8, two rows, a few
// blocks, and every row standing (4x1 → 1x4)
var QUICK_SIZES = ["4x1", "2x1", "3x1", "5x1", "6x1", "7x1", "8x1", "2x2", "3x2", "4x2", "5x2", "6x2", "8x2", "3x3", "4x3", "4x4", "1x2", "1x3", "1x4", "1x5", "1x6", "2x3", "2x4", "2x5", "2x6"];

// the calendar's sizes (2026-10-11): a month (3x3 and up), a week in a row (4x1…7x1), today (1x1, 2x1,
// 1x2, 2x2)
var CALENDAR_SIZES = ["3x3", "4x3", "3x4", "4x4", "5x4", "4x1", "5x1", "6x1", "7x1", "1x1", "2x1", "1x2", "2x2"];

// `styles` plus a Card variant after each style named in `withCard` (the Iwidgets' scheme, 2026-10-11):
// the no-card style is the parent and the default; `<base>Card` draws it on the card (DwidgetCard.qml)
function cards(styles, withCard) {
    var out = [];
    styles.forEach(function (s) {
        var parent = Object.assign({}, s);
        if (withCard.indexOf(s.id) >= 0)
            parent.variant = "No card";
        out.push(parent);
        if (withCard.indexOf(s.id) >= 0)
            out.push({ id: s.id + "Card", title: s.title + " (card)", group: s.id, variant: "Card", card: true, sizes: s.sizes });
    });
    return out;
}

// Dwidget styles renamed (old → new), kept instead of falling back to the default. Only ids that no
// longer exist (these run on every load): the old card styles that kept a reused id ("shapes" was the
// card one) fall to the new no-card style
var RENAMED = {
    quick: { shapesNoCard: "shapes", tonesNoCard: "tones" },
    sliders: { inset: "shapes", tonesNoCard: "tones", wavyNoCard: "tone", wavy: "toneCard" },
    // the earlier Expressive was two tones
    calendar: { expressiveNoCard: "tones", expressive: "tonesCard" },
    // the 2026-10-08 looks: Cover and Android drew on a card, Type was two tones; the old "disc" (the
    // card one) keeps its id and becomes the no-card Disc
    media: { cover: "shapesCard", android: "shapesCard", discNoCard: "disc", typeNoCard: "tones", type: "tonesCard" }
};

function renamed(id, styleId) {
    return RENAMED[id] && RENAMED[id].hasOwnProperty(styleId) ? RENAMED[id][styleId] : styleId;
}

var WIDGETS = {
    // debug: shows its id / style / size; for trying the layout engine and the expand modes
    placeholder: {
        title: "Placeholder",
        icon: "squaresFour",
        debug: true,
        styles: [
            { id: "box", title: "Box", sizes: ["2x2", "1x1", "2x1", "3x2", "4x3"] },
            { id: "tall", title: "Tall", sizes: ["1x2", "1x3", "3x3"] }
        ],
        defaults: { idle: { style: "box", size: "2x2" }, options: {} },
        expand: { size: "4x3", trigger: "click" }
    },
    // the Iwidget family (2026-10-11, redone from scratch): shapes, two tones, tone and disc (the extra:
    // a turning record in its wavy ring, as the island's), each also on the card (media/MediaView.qml)
    media: {
        title: "Media",
        icon: "player",
        styles: cards([
            { id: "shapes", title: "Shapes", sizes: MEDIA_SIZES },
            { id: "tones", title: "Two tones", sizes: MEDIA_SIZES },
            { id: "tone", title: "Tone", sizes: MEDIA_SIZES },
            { id: "disc", title: "Disc", sizes: MEDIA_SIZES }
        ], ["shapes", "tones", "tone", "disc"]),
        defaults: { idle: { style: "shapes", size: "4x2" }, options: {} }
    },
    // Qwidgets (quick/qwidgets.js) in the Iwidget family (quick/QuickView, QMark); the size arranges them
    // (icons when short or narrow, else pills). Every horizontal size has its vertical one (4x1 → 1x4). Quick configs expands only to show the
    // Mixer's panel (its click opens it); the other panels open in the toggle Dwidgets
    quick: {
        title: "Quick configs",
        icon: "gear",
        // the Iwidget family (2026-10-11, redone from scratch in the island's language): shapes, two
        // tones, tone, each also on the card
        styles: cards([
            { id: "shapes", title: "Shapes", sizes: QUICK_SIZES },
            { id: "tones", title: "Two tones", sizes: QUICK_SIZES },
            { id: "tone", title: "Tone", sizes: QUICK_SIZES }
        ], ["shapes", "tones", "tone"]),
        defaults: { idle: { style: "shapes", size: "4x1" }, options: {} },
        // only to show the Mixer's panel (a click on the Mixer Qwidget): no event of its own
        expand: { size: "6x5", trigger: "none", panelOnly: true }
    },
    calendar: {
        title: "Calendar",
        icon: "calendarBlank",
        // the Iwidget family (2026-10-11, redone from scratch): shapes, two tones, tone, each also on the
        // card; the size picks the layout (calendar/CalendarView.qml)
        styles: cards([
            { id: "shapes", title: "Shapes", sizes: CALENDAR_SIZES },
            { id: "tones", title: "Two tones", sizes: CALENDAR_SIZES },
            { id: "tone", title: "Tone", sizes: CALENDAR_SIZES }
        ], ["shapes", "tones", "tone"]),
        defaults: { idle: { style: "shapes", size: "3x3" }, options: {} }
    },
    // system levels: the Swidgets in options.items (sliders/swidgets.js), vertical side by side
    // when the rect is at least as tall as wide, else stacked; Google's M3 sliders (flat or wavy).
    // Every horizontal size has its vertical one (3x1 → 1x3)
    sliders: {
        title: "Sliders",
        icon: "sliders",
        // the Iwidget family (2026-10-11): shapes, two tones, tone, each also on the card
        styles: cards([
            { id: "shapes", title: "Shapes", sizes: SLIDERS_SIZES },
            { id: "tones", title: "Two tones", sizes: SLIDERS_SIZES },
            { id: "tone", title: "Tone", sizes: SLIDERS_SIZES }
        ], ["shapes", "tones", "tone"]),
        defaults: { idle: { style: "shapes", size: "4x1" }, options: {} }
    }
};

// Wi-Fi, Bluetooth and Mixer as their own Dwidgets (toggle/Widget.qml; the other Qwidgets only go in
// Quick configs): the toggle (2x1 lying, 1x1 the icon, 1x2 standing, 2x2 / 3x2 a card). Their panel is
// reached only by expanding, at a fixed size the user doesn't pick (Wi-Fi / Bluetooth 4x6; the mixer
// a wide 6x5 (bigger since 2026-10-17, user), the devices at the left and the apps at the right).
// 1x1 … 2x2 the compact toggle; 3x3 and up the panel is the face (2026-10-27, user)
var TOGGLE_SIZES = ["2x1", "1x1", "3x1", "1x2", "2x2", "3x3", "4x3", "3x4", "4x4", "5x4", "4x5", "4x6", "5x5", "6x4", "6x5", "6x6", "6x7"];
function toggleWidget(title, icon, expandSize, trigger) {
    return {
        title: title,
        icon: icon,
        // the Quick configs looks (2026-10-11): shapes, two tones, tone, each also on the card
        styles: cards([
            { id: "shapes", title: "Shapes", sizes: TOGGLE_SIZES },
            { id: "tones", title: "Two tones", sizes: TOGGLE_SIZES },
            { id: "tone", title: "Tone", sizes: TOGGLE_SIZES }
        ], ["shapes", "tones", "tone"]),
        defaults: { idle: { style: "shapes", size: "2x1" }, options: {} },
        expand: { size: expandSize, trigger: trigger || "doubleclick" }
    };
}
WIDGETS.wifi = toggleWidget("Wi-Fi", "wifiHigh", "4x6");
WIDGETS.bluetooth = toggleWidget("Bluetooth", "bluetooth", "4x6");
// the Mixer's click opens its panel (it doesn't mute)
WIDGETS.mixer = toggleWidget("Mixer", "faders", "6x7", "click");
// (2026-10-27, user: every toggle has a panel) the colour scheme and the wallpaper act on a click (the next
// scheme, the Wallpaper app), the power profile cycles
WIDGETS.colorScheme = toggleWidget("Color scheme", "palette", "4x6");
WIDGETS.powerProfile = toggleWidget("Power profile", "gauge", "4x5");
WIDGETS.wallpaper = toggleWidget("Wallpaper", "image", "5x6");

// the apps' summaries (summary/Widget.qml, 2026-10-17, user): Notifications, Clipboard, Notes and (2026-10-27)
// Dino run. 1x1 / 2x1 / 1x2 a badge (the count), 2x2 and up a list of the latest items; they never expand
// (a click acts or opens the app). Helper gets none
// (2026-10-27, user: more rectangles, 2 and 3 thick; wide lists flow into columns)
var SUMMARY_SIZES = ["3x3", "1x1", "2x1", "1x2", "2x2", "3x2", "4x2", "5x2", "6x2", "7x2", "8x2", "2x3", "4x3", "5x3", "6x3", "7x3",
    "2x4", "2x5", "2x6", "2x7", "2x8", "3x4", "3x5", "3x6", "4x4"];
function summaryWidget(title, icon) {
    return {
        title: title,
        icon: icon,
        styles: cards([
            { id: "shapes", title: "Shapes", sizes: SUMMARY_SIZES },
            { id: "tones", title: "Two tones", sizes: SUMMARY_SIZES },
            { id: "tone", title: "Tone", sizes: SUMMARY_SIZES }
        ], ["shapes", "tones", "tone"]),
        defaults: { idle: { style: "shapes", size: "3x3" }, options: {} }
    };
}
WIDGETS.notifications = summaryWidget("Notifications", "bell");
WIDGETS.clipboard = summaryWidget("Clipboard", "clipboard");
WIDGETS.notes = summaryWidget("Notes", "notes");
WIDGETS.dino = summaryWidget("Dino run", "dino");

// "single" Dwidgets (2026-10-27, user): an image / GIF from the system (square sizes, a minimal start), the
// clock and the music visualizer. They never expand
// squares, then (2026-10-27, user) rectangles both ways, up to 6x4 / 4x6
var IMAGE_SIZES = ["2x2", "1x1", "3x3", "4x4", "5x5", "6x6", "2x1", "1x2", "3x1", "1x3", "3x2", "2x3", "4x2", "2x4",
    "4x3", "3x4", "5x3", "3x5", "6x3", "3x6", "5x4", "4x5", "6x4", "4x6"];
WIDGETS.image = {
    title: "Image",
    icon: "image",
    styles: cards([
        { id: "image", title: "Image", sizes: IMAGE_SIZES }
    ], ["image"]),
    defaults: { idle: { style: "image", size: "2x2" }, options: {} }
};
var CLOCK_SIZES = ["3x2", "2x1", "3x1", "4x1", "2x2", "4x2", "3x3"];
WIDGETS.clock = {
    title: "Clock",
    icon: "clock",
    styles: cards([
        { id: "shapes", title: "Shapes", sizes: CLOCK_SIZES },
        { id: "tones", title: "Two tones", sizes: CLOCK_SIZES },
        { id: "tone", title: "Tone", sizes: CLOCK_SIZES }
    ], ["shapes", "tones", "tone"]),
    defaults: { idle: { style: "shapes", size: "3x2" }, options: {} }
};
var VISUALIZER_SIZES = ["4x2", "2x1", "3x1", "4x1", "6x1", "2x2", "3x2", "6x2"];
WIDGETS.visualizer = {
    title: "Visualizer",
    icon: "visualizer",
    styles: cards([
        { id: "bars", title: "Bars", sizes: VISUALIZER_SIZES },
        { id: "dots", title: "Dots", sizes: VISUALIZER_SIZES },
        { id: "shapes", title: "Shapes", sizes: VISUALIZER_SIZES }
    ], ["bars", "dots", "shapes"]),
    defaults: { idle: { style: "bars", size: "4x2" }, options: {} }
};

function has(id) {
    return WIDGETS.hasOwnProperty(id);
}

function style(id, styleId) {
    if (!has(id))
        return null;
    var list = WIDGETS[id].styles;
    for (var i = 0; i < list.length; i++)
        if (list[i].id === styleId)
            return list[i];
    return null;
}

function validStyle(id, styleId) {
    return style(id, styleId) !== null;
}

// what the Dwidget draws for a style (a Card variant's parent) and whether the card goes behind it
function baseStyle(id, styleId) {
    var s = style(id, styleId);
    return s && s.group && s.card ? s.group : styleId;
}
function isCard(id, styleId) {
    var s = style(id, styleId);
    return !!(s && s.card);
}

// is `size` one of the sizes style `styleId` of Dwidget `id` allows
function validSize(id, styleId, size) {
    var s = style(id, styleId);
    return s !== null && s.sizes.indexOf(size) >= 0;
}

// "3x2" → { w: 3, h: 2 }; anything else → null
function parseSize(size) {
    var m = /^(\d+)x(\d+)$/.exec(String(size));
    if (!m)
        return null;
    var w = parseInt(m[1]), h = parseInt(m[2]);
    return w > 0 && h > 0 ? { w: w, h: h } : null;
}

// a valid { style, size } for Dwidget `id` from `mode`, falling back to `fallback` (a mode):
// a bad style → the fallback's; a size the style doesn't allow → the style's first size
function validMode(id, mode, fallback) {
    var m = mode && typeof mode === "object" ? mode : {};
    var st = validStyle(id, m.style) ? m.style : fallback.style;
    var sizes = style(id, st).sizes;
    return { style: st, size: sizes.indexOf(m.size) >= 0 ? m.size : (sizes.indexOf(fallback.size) >= 0 && st === fallback.style ? fallback.size : sizes[0]) };
}

// whether Dwidget `id` expands at all (its catalog `expand`)
function expands(id) {
    return has(id) && !!WIDGETS[id].expand;
}

// whether Dwidget `id` has an expand event the user picks (it expands, and not only for a panel)
function hasEvent(id) {
    return expands(id) && !WIDGETS[id].expand.panelOnly;
}

// the entry's expand event: for a Dwidget with one, the entry's own `expandOn` (click ·
// doubleclick · hover · none, set in the editor) or the catalog's trigger; else none
function trigger(entry) {
    if (!entry || !hasEvent(entry.id))
        return "none";
    return TRIGGERS.indexOf(entry.expandOn) >= 0 ? entry.expandOn : WIDGETS[entry.id].expand.trigger;
}

// the size an entry expands to ("WxH"): its Dwidget's, else its own size
function expandedSize(entry) {
    if (!entry)
        return null;
    var x = has(entry.id) ? WIDGETS[entry.id].expand : null;
    return x ? x.size : (entry.idle ? entry.idle.size : null);
}

// a new entry for Dwidget `id` at x, y (uid must be unique in the layout)
function defaultEntry(id, uid, x, y) {
    var d = WIDGETS[id].defaults;
    return {
        uid: uid,
        id: id,
        idle: { style: d.idle.style, size: d.idle.size },
        x: x || 0,
        y: y || 0,
        off: false,
        options: JSON.parse(JSON.stringify(d.options))
    };
}
