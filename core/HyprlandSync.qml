import QtQml
import Quickshell
import Quickshell.Io
import "./config-shape.mjs" as ConfigShape

// 0.507: whenever config.hyprland changes and consent (decision 10.3b) is
// given, spawns `vtnc hyprland generate`, which writes
// ~/.config/hypr/vtnc/keybinds.lua and runs `hyprctl reload` — this is "a
// shell roda hyprctl reload sozinha" (decision 7.2): the running shell
// triggers it, `vtnc hyprland set` itself never does (decision 4b.4, same
// as every other namespace's `set`).
//
// Comparing JSON.stringify(hyprland), not Config.data as a whole, keeps
// this from re-running on every unrelated config.json write (editing an
// island, say) — only an actual change to the hyprland section itself
// counts. A fresh shell start also counts as a change (lastSignature
// starts empty), so a reboot or a `qs -c` restart re-syncs on its own if
// consent was already given in an earlier session.
QtObject {
    id: root

    required property var configRef

    property string lastSignature: ""

    function sync() {
        const hyprland = root.configRef.data.hyprland ?? ConfigShape.defaultHyprland();
        const signature = JSON.stringify(hyprland);
        if (signature === root.lastSignature) return;
        root.lastSignature = signature;
        if (!hyprland.enabled) return;

        const proc = procComponent.createObject(root);
        if (proc) proc.running = true;
    }

    property Component procComponent: Component {
        Process {
            command: [Quickshell.shellDir + "/cli/vtnc", "hyprland", "generate"]
            onRunningChanged: if (!running) destroy()
        }
    }

    property Connections watcher: Connections {
        target: root.configRef
        function onDataChanged() { root.sync(); }
    }

    Component.onCompleted: root.sync()
}
