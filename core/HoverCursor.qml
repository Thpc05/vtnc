pragma Singleton

import QtQml
import Quickshell.Io

// Where the mouse is, in Hyprland's own global pixel coordinates (0.505,
// decision 11.2d). There's no "hover but let the click through" surface in
// wlr-layer-shell — an input region that receives pointer-enter receives
// the click under it too — so a hidden island's reveal strip can't be a
// real surface at all without stealing clicks from whatever is behind it.
// Polling `hyprctl cursorpos` read-only (AGENTS.md: reading Hyprland state
// is in scope for 0.505) sidesteps that: the hidden island has no extra
// surface near the border, just this number, compared in
// core/grid.mjs's cursorNearBorder/cursorOverRect.
QtObject {
    id: root

    property var pos: ({ x: -1, y: -1 }) // off-screen until the first poll lands

    property Component pollComponent: Component {
        Process {
            id: proc
            command: ["hyprctl", "-j", "cursorpos"]
            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: {
                    try {
                        root.pos = JSON.parse(text);
                    } catch (e) {
                        // hyprctl unreachable (no Hyprland yet, or between
                        // nested-compositor restarts in a test) — keep the
                        // last known position rather than throw.
                    }
                    proc.destroy();
                }
            }
        }
    }

    property Timer poller: Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            const proc = root.pollComponent.createObject(root);
            if (proc) proc.running = true;
        }
    }
}
