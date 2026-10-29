import QtQuick

// Base of every Dwidget (see README.md, "Dwidget contract"). apps/dashboard/Cell.qml sets these
// and sizes the Dwidget to its rect; the Dwidget just fills itself.
Item {
    // the look to render now: the idle or the expanded mode's style (catalog.js)
    property string style
    // the current size in cells, { w, h } (the expanded size while expanded)
    property var size: ({
            w: 1,
            h: 1
        })
    // the rect it's going to, in px (the cell animates its own size toward it): what to lay out by, so
    // a layout chosen by size doesn't flip while the cell moves (2026-10-16)
    property real targetWidth: width
    property real targetHeight: height
    property bool expanded: false
    // the entry has an expand event; expandRequest is ignored without one
    property bool expandable: false
    // that event: click · doubleclick · hover · none (a Dwidget whose own click acts, like a toggle,
    // handles click / double click itself)
    property string trigger: "none"
    // the entry's options (dashboard.widgets[i].options); read only here
    property var options: ({})
    // true inside the settings preview: render only, no service writes, no side effects
    property bool editing: false

    // ask the dashboard to expand (true) or collapse (false) this Dwidget, e.g. to show a panel in the
    // expanded rect (only when expandable)
    signal expandRequest(bool on)
}
