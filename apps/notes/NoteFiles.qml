import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// The notes on disk (2026-10-17): one <name>.md per note in Settings → Apps → Notes → Notes folder; a
// note's title is its first line. `notes`: [{ file, mtime, title }], pinned ones first (state.json
// apps.notes.pins), then the newest. The open note is read and written by the view (Note.qml's FileView).
QtObject {
    id: root

    readonly property string dir: Store.expandPath(Store.appOptions.notes?.dir || "~/.local/share/vtnc/notes")
    property var notes: []
    readonly property var pins: Store.appGet("notes", "pins", [])

    function path(file: string): string {
        return dir + "/" + file;
    }

    function refresh() {
        if (!lister.running)
            lister.running = true;
    }

    function sorted(list: var): var {
        const p = pins;
        return list.filter(n => p.includes(n.file)).concat(list.filter(n => !p.includes(n.file)).sort((a, b) => b.mtime - a.mtime));
    }

    // a new empty note; its file name ("note-20261017-153012.md")
    function create(): string {
        const d = new Date();
        const two = n => String(n).padStart(2, "0");
        const file = `note-${d.getFullYear()}${two(d.getMonth() + 1)}${two(d.getDate())}-${two(d.getHours())}${two(d.getMinutes())}${two(d.getSeconds())}.md`;
        notes = [{
                file: file,
                mtime: Date.now() / 1000,
                title: ""
            }].concat(notes);
        notes = sorted(notes);
        run(["sh", "-c", 'mkdir -p "$1" && : > "$1/$2"', "sh", dir, file]);
        return file;
    }

    function remove(file: string) {
        notes = notes.filter(n => n.file !== file);
        setPinned(file, false);
        run(["rm", "-f", path(file)]);
    }

    function isPinned(file: string): bool {
        return pins.includes(file);
    }
    function setPinned(file: string, on: bool) {
        const p = pins.filter(f => f !== file);
        if (on)
            p.unshift(file);
        Store.appSet("notes", "pins", p);
        notes = sorted(notes);
    }

    // the open note was saved: its title and time in the list
    function touched(file: string, text: string) {
        const title = (text.split("\n")[0] ?? "").replace(/^#+\s*/, "").trim();
        notes = sorted(notes.map(n => n.file === file ? {
                file: n.file,
                mtime: Date.now() / 1000,
                title: title
            } : n));
    }

    function run(cmd: var) {
        const proc = runner.createObject(root, {
            command: cmd
        });
        proc.running = true;
    }
    readonly property Component runner: Component {
        Process {
            id: proc
            onExited: proc.destroy()
        }
    }

    // "<file>\t<mtime>\t<first line>" per note
    readonly property Process lister: Process {
        command: ["sh", "-c", 'mkdir -p "$1" && cd "$1" && for f in *.md; do [ -e "$f" ] || continue; printf "%s\\t%s\\t" "$f" "$(stat -c %Y "$f")"; head -n1 "$f" | tr -d "\\t\\r\\n"; printf "\\n"; done', "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const l of text.split("\n")) {
                    const p = l.split("\t");
                    if (p.length < 2)
                        continue;
                    out.push({
                        file: p[0],
                        mtime: Number(p[1]) || 0,
                        title: (p.slice(2).join("\t") ?? "").replace(/^#+\s*/, "").trim()
                    });
                }
                root.notes = root.sorted(out);
            }
        }
    }
}
