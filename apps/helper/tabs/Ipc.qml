import QtQuick
import Quickshell.Io
import ".."

// Helper → IPC (2026-10-17): every IPC target and function, live from `qs -c vtnc ipc show`; a row copies
// its `qs -c vtnc ipc call …` line.
HelperList {
    id: root

    placeholder: "Search IPC…"
    note: "Live from qs -c vtnc ipc show · Enter copies the call"
    heroIcon: "settings_ethernet"
    heroShape: "softBurst"
    heroTitle: "IPC commands"
    heroText: "Everything the running shell answers, through Quickshell: <b>qs -c vtnc ipc call &lt;target&gt; &lt;function&gt; [args]</b>. Use them in Hyprland binds, scripts or a terminal. Each target groups its functions; Enter or a click copies the call."
    keyWidth: 300

    function opened() {
        if (!show.running)
            show.running = true;
        reset();
    }

    // "target dino" / "  function toggle(): void" / "  function set(path: string): void"
    function parse(text: string): var {
        const out = [];
        let cur = null;
        for (const line of text.split("\n")) {
            const t = /^target\s+(\S+)/.exec(line);
            if (t) {
                cur = {
                    target: t[1],
                    title: t[1].charAt(0).toUpperCase() + t[1].slice(1),
                    rows: []
                };
                out.push(cur);
                continue;
            }
            const f = /^\s+function\s+(\w+)\(([^)]*)\)/.exec(line);
            if (f && cur) {
                const args = f[2].split(",").map(a => a.trim()).filter(a => a !== "").map(a => a.split(":")[0].trim());
                // "toggleAutohide" → "Toggle autohide"
                const words = f[1].replace(/([a-z])([A-Z])/g, "$1 $2").toLowerCase().replace(/\b(dnd|osd|ipc|ocr)\b/g, w => w.toUpperCase());
                const what = words.charAt(0).toUpperCase() + words.slice(1);
                cur.rows.push({
                    key: cur.target + " " + f[1] + (args.length ? " " + args.map(a => "<" + a + ">").join(" ") : ""),
                    // (the arguments are in the command)
                    text: what,
                    copy: "qs -c vtnc ipc call " + cur.target + " " + f[1]
                });
            }
        }
        out.sort((a, b) => a.title.localeCompare(b.title));
        for (const s of out)
            s.rows.sort((a, b) => a.key.localeCompare(b.key));
        return out;
    }

    Process {
        id: show
        command: ["qs", "-c", "vtnc", "ipc", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.sections = root.parse(text)
        }
    }
}
