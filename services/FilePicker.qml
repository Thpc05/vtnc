pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// The system's file chooser (zenity) for the shell's settings (2026-10-27, user). The island is an overlay
// that takes the screen's input while an app is open, so the chooser would open under it: `pick()` closes
// the app first, then shows the chooser, then calls back with the path (nothing when cancelled) and opens
// the app again on `reopen` ({ id, args }). It lives here, not in the page: the page goes with the app.
Singleton {
    id: root

    readonly property bool busy: proc.running
    property var callback: null
    property var reopen: null

    // filters: [{ name, patterns: ["*.png", …] }], offered after "All files", which opens first (user: a
    // file without an extension, as "jpg(1)", must show; a pattern can't match those)
    function pick(title: string, filters: var, done: var, reopenApp: var) {
        const args = ["zenity", "--file-selection", "--title=" + title, "--file-filter=All files | *"];
        for (const f of filters ?? [])
            args.push("--file-filter=" + f.name + " | " + f.patterns.join(" "));
        run(args, done, reopenApp);
    }
    // a folder instead of a file
    function pickFolder(title: string, done: var, reopenApp: var) {
        run(["zenity", "--file-selection", "--directory", "--title=" + title], done, reopenApp);
    }
    function run(args: var, done: var, reopenApp: var) {
        if (proc.running)
            return;
        callback = done;
        reopen = reopenApp ?? null;
        proc.command = args;
        Runtime.closeThen(() => proc.running = true);
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                const cb = root.callback;
                root.callback = null;
                if (path !== "")
                    cb?.(path);
                if (root.reopen)
                    Runtime.openApp(root.reopen.id, root.reopen.args ?? {});
                root.reopen = null;
            }
        }
    }
}
