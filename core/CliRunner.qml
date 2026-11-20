pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

// The one door between any QML in this shell and the real `cli/vtnc`
// binary. Settings uses this exclusively to change anything (decision
// 6.3's exception: the CLI writes direct, Settings never does) — it never
// touches Config or config.json itself. Acceptance criterion 4 of 0.503
// proves the boundary by making cli/vtnc non-executable and checking that
// nothing from the Islands page still reaches config.json.
QtObject {
    id: root

    property Component processComponent: Component {
        Process {}
    }

    function run(args) {
        const proc = processComponent.createObject(root, {
            command: [Quickshell.shellDir + "/cli/vtnc", ...args],
        });
        if (!proc) {
            console.warn("vtnc: CliRunner failed to create a process for", args);
            return;
        }
        // `running` flips back to false both when the command finishes
        // normally and when it never started at all (cli/vtnc not
        // executable) — one handler covers both ways this needs cleanup.
        proc.runningChanged.connect(function () {
            if (!proc.running) proc.destroy();
        });
        proc.running = true;
    }
}
