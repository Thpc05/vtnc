.pragma library

// The Settings pages (2026-10-29: out of View.qml, so the IPC can list them): top-level pages, some with
// sub-pages. `icon` is an Icons key; View.qml maps each page path to its component. A page's path is
// "<id>" or "<parent id>/<id>"; IPC `settings page <path | id | title>` opens one, `settings pages` lists them.
var TREE = [
    { id: "appearance", title: "Appearance", icon: "paintBrush", children: [
        { id: "general", title: "General" },
        { id: "colors", title: "Colors" },
        { id: "popups", title: "Popups" }
    ] },
    { id: "island", title: "Island", icon: "island", children: [
        { id: "general", title: "General" },
        { id: "layout", title: "Layout" },
        { id: "anchors", title: "Anchors" },
        { id: "autohide", title: "Auto hide" }
    ] },
    { id: "dashboard", title: "Dashboard", icon: "squaresFour", children: [
        { id: "general", title: "General" },
        { id: "layout", title: "Layout" }
    ] },
    { id: "apps", title: "Apps", icon: "apps", children: [
        { id: "notifications", title: "Notifications" },
        { id: "clipboard", title: "Clipboard" },
        { id: "notes", title: "Notes" },
        { id: "session", title: "Session" },
        { id: "tools", title: "Tools" },
        { id: "wallpaper", title: "Wallpaper" },
        { id: "dino", title: "Dino run" }
    ] },
    { id: "presets", title: "Presets", icon: "stack" },
    { id: "system", title: "System", icon: "slidersHorizontal" },
    { id: "about", title: "About", icon: "info", children: [
        { id: "general", title: "General" },
        { id: "components", title: "Examples" }
    ] }
];

// every selectable page in order: { path, title, parentTitle }
function leaves() {
    var out = [];
    for (var i = 0; i < TREE.length; i++) {
        var n = TREE[i];
        if (n.children && n.children.length) {
            for (var j = 0; j < n.children.length; j++)
                out.push({ path: n.id + "/" + n.children[j].id, title: n.children[j].title, parentTitle: n.title });
        } else {
            out.push({ path: n.id, title: n.title, parentTitle: "" });
        }
    }
    return out;
}

function isLeaf(path) {
    return leaves().some(function (l) { return l.path === path; });
}

// a parent path resolves to its first sub-page, the old paths to their new place, unknown ones to the first page
function resolve(path) {
    // Island → Iwidgets became Island → Layout (2026-10-09)
    if (path === "island/widgets")
        path = "island/layout";
    // Island → OSD became Appearance → OSD (2026-10-15); OSD and Notifications became Popups (2026-10-17)
    if (path === "island/osd" || path === "appearance/osd" || path === "appearance/notifications")
        path = "appearance/popups";
    if (isLeaf(path))
        return path;
    for (var i = 0; i < TREE.length; i++) {
        var n = TREE[i];
        if (n.id === path && n.children && n.children.length)
            return n.id + "/" + n.children[0].id;
    }
    return leaves()[0].path;
}

// what the IPC was given: a path ("island/autohide"), a sub-page's title ("Auto hide") or a top-level id or
// title, case and spaces ignored. Returns the resolved path, or "" when nothing matches
function find(query) {
    var q = String(query).toLowerCase().replace(/\s+/g, "");
    var flat = function (s) { return s.toLowerCase().replace(/\s+/g, ""); };
    var ls = leaves();
    for (var i = 0; i < ls.length; i++)
        if (ls[i].path === q || flat(ls[i].title) === q)
            return ls[i].path;
    for (var j = 0; j < TREE.length; j++)
        if (TREE[j].id === q || flat(TREE[j].title) === q)
            return resolve(TREE[j].id);
    return "";
}
