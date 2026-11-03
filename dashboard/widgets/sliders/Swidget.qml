import QtQuick

// A Swidget's live level (see swidgets.js). Each one in swidgets/<Id>.qml binds these to its
// service and defines `function set(v)` (the user moved it, 0–1) and `function iconClicked()`.
QtObject {
    // the Material Symbols glyph for its current state
    property string symbol
    property real iconFill: 1
    property real value: 0
    // dimmed fill (muted, off)
    property bool muted: false
    // false = its service isn't there yet: inert
    property bool ready: true
}
