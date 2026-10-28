import QtQuick
import qs.core

// Dashboard: a grid of Dwidgets (dwidgets/README.md). The layout comes from Store.dashboard;
// the view only holds which entry is expanded (not persisted).
// Esc collapses the expanded entry first, then closes the dashboard.
FocusScope {
    id: root

    readonly property var config: Store.dashboard

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    // expand (on) or collapse entry `uid`; one entry at most is expanded
    function expand(uid: string, on: bool) {
        if (on && grid.expandedUid === uid || !on && grid.expandedUid !== uid)
            return;
        // the curve direction first: the cells' Behaviors read it when the rects change
        grid.growing = on;
        grid.expandedUid = on ? uid : "";
    }

    function opened() {
        root.forceActiveFocus();
        grid.enter();
    }

    function closed() {
        root.expand(grid.expandedUid, false);
    }

    Keys.onEscapePressed: event => {
        if (grid.expandedUid !== "") {
            root.expand(grid.expandedUid, false);
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }

    DashboardGrid {
        id: grid
        anchors.fill: parent
        entries: root.config.widgets ?? []
        cell: Math.max(40, root.config.cell || 80)
        gap: Math.max(0, root.config.gap ?? 8)
        mode: root.config.expandMode || "over"
        onExpandRequest: (uid, on) => root.expand(uid, on)
    }
}
