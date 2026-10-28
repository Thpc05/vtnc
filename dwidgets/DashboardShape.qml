pragma Singleton
import QtQuick
import Quickshell
import qs.core

// The shape every Shapes mark opens the dashboard with (2026-10-16, user: in sync on each open; after
// that each one changes on its own events). RandomShape instances take it when `opens` changes.
Singleton {
    id: root

    // no clovers: their deep lobes crowd an icon or a number
    readonly property var shapes: ["cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "sunny", "softBurst"]
    property string shape: pick("")
    property int opens: 0

    function pick(not: string): string {
        let s;
        do {
            s = shapes[Math.floor(Math.random() * shapes.length)];
        } while (s === not && shapes.length > 1);
        return s;
    }

    readonly property bool dashboardOpen: Runtime.activeApp === "dashboard"
    onDashboardOpenChanged: if (dashboardOpen) {
        shape = pick(shape);
        opens++;
    }
}
