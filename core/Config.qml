pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import "./config-shape.mjs" as ConfigShape

// The config file is config (decision 6.5): user-editable JSON, read here and
// written directly by the CLI (decision 4b.4). This singleton only reads —
// watchChanges makes it pick up a CLI `set` live, with no IPC round-trip.
QtObject {
    id: root

    property var data: ConfigShape.defaultConfig()

    readonly property FileView view: FileView {
        path: Paths.configFile
        watchChanges: true

        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {
                console.warn("vtnc: config.json is not valid JSON, keeping defaults:", e);
            }
        }

        onLoadFailed: (error) => {
            // Missing file is normal on a fresh install: keep defaults.
            root.data = ConfigShape.defaultConfig();
        }

        onFileChanged: reload()
    }

    function island(name) {
        return ConfigShape.findIsland(data, name);
    }

    function page(name) {
        return ConfigShape.findPage(data, name);
    }
}
