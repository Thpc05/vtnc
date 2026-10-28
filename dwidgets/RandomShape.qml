import QtQuick
import qs.core
import qs.dwidgets

// A random M3 shape for the Dwidgets' Shapes look (2026-10-16, user): each time the dashboard opens every
// mark takes the same new one (DashboardShape, in sync), then a mark picks its own on `next()` (a Qwidget
// turning on, connecting or disconnecting). The open's change is `instant` (no morph: it isn't an event,
// it's a fresh look). With the Dwidget's Random shapes off (`enabled`) its users go back to their own
// look and nothing re-picks.
QtObject {
    id: root

    readonly property var shapes: DashboardShape.shapes
    // the Dwidget's option (options.randomShapes, 2026-10-17: each Dwidget its own)
    property bool enabled: true
    // not a binding: it changes only on an open (instant) or an event
    property string picked
    Component.onCompleted: picked = DashboardShape.shape
    readonly property string shape: picked
    property bool instant: false

    function pick(not: string): string {
        let s;
        do {
            s = shapes[Math.floor(Math.random() * shapes.length)];
        } while (s === not && shapes.length > 1);
        return s;
    }
    function next() {
        if (enabled)
            picked = pick(picked);
    }

    readonly property int opens: DashboardShape.opens
    onOpensChanged: {
        instant = true;
        picked = DashboardShape.shape;
        Qt.callLater(() => root.instant = false);
    }
}
