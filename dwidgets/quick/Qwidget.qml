import QtQuick

// A Qwidget's live state (see ../README.md, "Quick configs"). Each one in qwidgets/<Id>.qml
// binds these to its service and defines `function toggle()` (a plain click).
QtObject {
    // its catalog id (qwidgets.js) and its instance's options ({ target } for an App; {} for most)
    property string qid
    property var config: ({})
    property string title
    // the glyph for its current state (theme/Icons.qml)
    property string icon
    // the same, as a Material Symbols name (styles with icons.family "material")
    property string symbol
    property bool active: false
    // false = its service isn't there (no mic, no power-profiles-daemon…): shown dimmed, inert
    property bool available: true
    // short state text for the tiles / list styles ("Home", "4500 K", "Off")
    property string status: active ? "On" : "Off"
    // the page shown when it's opened (chevron / right-click), or null
    property Component panel: null
    // a click opens the panel instead of toggling (the Mixer); no switch in the panel header
    property bool opensPanel: false
    // an on / off to switch in the panel header (false: an action, the scheme, the wallpaper)
    property bool switchable: true
    // an extra button in the panel header, e.g. rescan: { icon (a Material Symbols name), run: function() {…} } or null
    property var action: null
    // an image icon instead of the symbol (an app's icon; "" = the symbol)
    property string image: ""
    // it's about to do something drastic (an armed session action): the error colour
    property bool danger: false
    // a right click when it has no panel (the colour scheme goes back one), or null
    property var alternate: null
}
