import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Helper → Keys (2026-10-17): the shortcuts, read for now from vtnc's Hyprland file
// (~/.config/hypr/vtnc/keybinds.lua: its `bind_ipc("KEYS", "target call")` lines, its `----- Name -----`
// comments as the sections). The keybind system will replace this source.
HelperList {
    id: root

    placeholder: "Search shortcuts…"
    note: "From ~/.config/hypr/vtnc/keybinds.lua"
    heroIcon: "keyboard"
    heroShape: "cookie9"
    heroTitle: "Keyboard shortcuts"
    heroText: "The keys that open the apps and drive the island. Hold the keys on the left together; Super is the Windows key.<br>Enter or a click copies the shortcut's IPC call, to use it from a script."
    keyWidth: 230

    function opened() {
        file.reload();
        reset();
    }

    // "launcher toggle" → "Launcher: toggle"; "tools screenshot region" → "Tools: screenshot region"
    function describe(call: string): string {
        const parts = call.trim().split(/\s+/);
        const target = parts[0] ?? "";
        const name = target.charAt(0).toUpperCase() + target.slice(1);
        return parts.length > 1 ? name + ": " + parts.slice(1).join(" ") : name;
    }

    // Hyprland's names → caps: "SUPER + Super_L" → Super (the key alone), slash → /, COMMA → ,
    readonly property var names: ({
            super_l: "Super",
            super: "Super",
            slash: "/",
            comma: ",",
            period: ".",
            escape: "Esc",
            return: "Enter",
            space: "Space",
            shift: "Shift",
            ctrl: "Ctrl",
            control: "Ctrl",
            alt: "Alt",
            print: "Print"
        })
    function keyNames(combo: string): var {
        const out = [];
        for (const k of combo.split("+").map(k => k.trim())) {
            const n = names[k.toLowerCase()] ?? (k.length === 1 ? k.toUpperCase() : k.charAt(0) + k.slice(1).toLowerCase());
            if (!out.includes(n))
                out.push(n);
        }
        return out;
    }

    function parse(text: string): var {
        const out = [];
        let section = {
            title: "",
            rows: []
        };
        for (const line of text.split("\n")) {
            const head = /^-{3,}\s*(.+?)\s*-{3,}\s*$/.exec(line.trim());
            if (head) {
                if (section.rows.length > 0)
                    out.push(section);
                section = {
                    title: head[1],
                    rows: []
                };
                continue;
            }
            const b = /^\s*bind_ipc\(\s*"([^"]+)"\s*,\s*"([^"]+)"/.exec(line);
            if (!b)
                continue;
            section.rows.push({
                keys: keyNames(b[1]),
                text: describe(b[2]),
                copy: "qs -c vtnc ipc call " + b[2]
            });
        }
        if (section.rows.length > 0)
            out.push(section);
        return out;
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/hypr/vtnc/keybinds.lua"
        printErrors: false
        onLoaded: root.sections = root.parse(text())
    }
}
