pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// The clipboard history (2026-10-17): cliphist keeps it (~/.cache/cliphist/db), the shell feeds it.
//  - while the shell runs, `wl-paste --watch cliphist store` stores every copy (text; images when
//    Settings → Apps → Clipboard → Keep images is on), with its History size as -max-items
//  - entries: `cliphist list`, newest first, read on `refresh()` (the app opening, after a change)
//    { id, line, text, image, mime, size, dims }; an image's thumbnail is decoded on demand to
//    ~/.cache/vtnc/clipboard/<id>.<ext> (`thumb(entry)`, `thumbsVersion` bumps when one is ready)
//  - pins: ids kept in state.json (apps.clipboard.pins; cliphist has none), shown first
Singleton {
    id: root

    readonly property var cfg: Store.appOptions.clipboard
    readonly property int maxItems: Math.max(10, cfg?.maxItems || 750)
    readonly property bool images: cfg?.images ?? true
    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/vtnc/clipboard"

    property var entries: []
    property bool loading: false
    property int thumbsVersion: 0
    readonly property var pins: Store.appGet("clipboard", "pins", [])

    // the watchers ------------------------------------------------------------
    // (a new History size restarts them: a running Process keeps its old command)
    property bool watching: Store.ready
    onMaxItemsChanged: if (watching) {
        watching = false;
        Qt.callLater(() => root.watching = Qt.binding(() => Store.ready));
    }
    Process {
        running: root.watching
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "-max-items", String(root.maxItems), "store"]
    }
    Process {
        running: root.watching && root.images
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "-max-items", String(root.maxItems), "store"]
    }

    // the list ----------------------------------------------------------------
    function refresh() {
        if (lister.running)
            return;
        loading = true;
        lister.running = true;
    }

    // "324\t[[ binary data 153 KiB png 1920x1080 ]]"
    function parse(line: string): var {
        const tab = line.indexOf("\t");
        if (tab < 0)
            return null;
        const id = line.slice(0, tab);
        const text = line.slice(tab + 1);
        const m = /^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]$/.exec(text);
        return {
            id: id,
            line: line,
            text: m ? "" : text,
            image: m !== null,
            mime: m ? m[2] : "",
            size: m ? m[1] : "",
            dims: m ? m[3].replace("x", " × ") : ""
        };
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const l of text.split("\n")) {
                    const e = l !== "" ? root.parse(l) : null;
                    if (e)
                        out.push(e);
                }
                const pinned = root.pins;
                root.entries = out.filter(e => pinned.includes(e.id)).concat(out.filter(e => !pinned.includes(e.id)));
                root.loading = false;
            }
        }
        onExited: code => {
            if (code !== 0)
                root.loading = false;
        }
    }

    // actions -----------------------------------------------------------------
    // the entry back on the clipboard (an image with its type)
    function copy(entry: var) {
        if (!entry)
            return;
        const type = entry.image ? "image/" + entry.mime : "";
        Quickshell.execDetached(["sh", "-c", 'if [ -n "$2" ]; then printf "%s" "$1" | cliphist decode | wl-copy -t "$2"; else printf "%s" "$1" | cliphist decode | wl-copy; fi', "sh", entry.line, type]);
    }

    function remove(entry: var) {
        if (!entry)
            return;
        entries = entries.filter(e => e.id !== entry.id);
        setPinned(entry, false);
        run(["sh", "-c", 'printf "%s" "$1" | cliphist delete; rm -f "$2"/"$3".*', "sh", entry.line, cacheDir, entry.id]);
    }

    function wipe() {
        entries = [];
        Store.appSet("clipboard", "pins", []);
        run(["sh", "-c", 'cliphist wipe; rm -rf "$1"', "sh", cacheDir]);
    }

    function isPinned(entry: var): bool {
        return entry !== null && pins.includes(entry.id);
    }
    function setPinned(entry: var, on: bool) {
        const p = pins.filter(id => id !== entry.id);
        if (on)
            p.unshift(entry.id);
        Store.appSet("clipboard", "pins", p);
        entries = entries.filter(e => p.includes(e.id)).sort((a, b) => p.indexOf(a.id) - p.indexOf(b.id)).concat(entries.filter(e => !p.includes(e.id)));
    }

    // a one-off command (the list is already updated in memory)
    function run(cmd: var) {
        const proc = runner.createObject(root, {
            command: cmd
        });
        proc.running = true;
    }
    Component {
        id: runner
        Process {
            id: proc
            onExited: proc.destroy()
        }
    }

    // thumbnails --------------------------------------------------------------
    // the decoded image's path ("" until it's there; asks for it once)
    property var thumbs: ({})
    function thumb(entry: var): string {
        if (!entry?.image)
            return "";
        const path = cacheDir + "/" + entry.id + "." + entry.mime;
        const state = thumbs[entry.id];
        if (state === "ready")
            return "file://" + path;
        if (state === undefined) {
            const t = Object.assign({}, thumbs);
            t[entry.id] = "pending";
            thumbs = t;
            const proc = decoder.createObject(root, {
                entryId: entry.id,
                command: ["sh", "-c", 'mkdir -p "$2" && [ -s "$3" ] || printf "%s" "$1" | cliphist decode > "$3"', "sh", entry.line, cacheDir, path]
            });
            proc.running = true;
        }
        return "";
    }
    Component {
        id: decoder
        Process {
            id: proc
            property string entryId
            onExited: code => {
                const t = Object.assign({}, root.thumbs);
                t[proc.entryId] = code === 0 ? "ready" : "failed";
                root.thumbs = t;
                root.thumbsVersion++;
                proc.destroy();
            }
        }
    }
}
