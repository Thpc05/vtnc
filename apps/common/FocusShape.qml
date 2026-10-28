import QtQuick

// The current item's M3 shape in the apps' Shapes look (2026-10-17, user: the workspaces Iwidget's focus
// shape, iwidgets/workspaces/TonesStyle.qml): a random other one on every move (`next()`), a new one
// with no morph each time the app opens (`reshuffle()`; `instant` while it swaps).
QtObject {
    id: root

    readonly property var shapes: ["cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "sunny", "softBurst", "clover4", "clover8"]
    // (not `pick()` here: it reads `shape`, a binding loop)
    property string shape: ""
    property bool instant: false
    Component.onCompleted: shape = pick()

    function pick(): string {
        const kinds = shapes.filter(k => k !== shape);
        return kinds[Math.floor(Math.random() * kinds.length)];
    }
    function next() {
        shape = pick();
    }
    function reshuffle() {
        instant = true;
        shape = pick();
        Qt.callLater(() => root.instant = false);
    }
}
