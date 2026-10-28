pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Wallpapers: list + thumbnails of Store.wallpapers.dir, apply with awww, colors with matugen.
//  - thumbnails: ~/.cache/vtnc/thumbs/<md5(path)>.jpg (vipsthumbnail, generated in background)
//  - awww grows the new wallpaper from the top (where the island is)
//  - matugen's whole output (every role of both schemes, the tonal palettes) goes to
//    ~/.cache/vtnc/matugen.json, which Colors watches and maps to the shell's tokens (theme/colorRoles.js)
Singleton {
    id: root

    readonly property string dir: Store.expandPath(Store.wallpapers.dir)
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/vtnc"
    readonly property string thumbDir: cacheDir + "/thumbs"
    readonly property string colorsFile: cacheDir + "/matugen.json"

    property var list: []                  // absolute paths, sorted
    readonly property string current: Store.wallpaper.current
    property int thumbsVersion: 0          // bumped when new thumbnails are ready
    property bool scanning: false

    readonly property var schemes: ["scheme-tonal-spot", "scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-vibrant"]

    function thumbFor(path: string): string {
        return `file://${thumbDir}/${Qt.md5(path)}.jpg`;
    }

    function name(path: string): string {
        return path.split("/").pop();
    }

    function refresh() {
        if (lister.running)
            return;
        scanning = true;
        lister.running = true;
    }

    function apply(path: string) {
        if (path === "")
            return;
        Store.wallpaper.current = path;
        show(path);
    }

    // the path awww was last told to show ("" until the startup query answered)
    property string shown: ""

    function show(path: string) {
        shown = path;
        Quickshell.execDetached(["awww", "img", path, "--transition-type", Store.wallpapers.transition, "--transition-pos", "top", "--transition-duration", "1.2", "--transition-fps", "60"]);
        regenDebounce.restart();
    }

    // the config changed it (a preset, Revert, an edited appearance.json): show it
    onCurrentChanged: if (shown !== "" && current !== "" && current !== shown)
        show(current)

    // random wallpaper from the folder, never the current one
    function applyRandom() {
        const pool = list.filter(p => p !== current);
        if (pool.length === 0) {
            console.warn("[Wallpapers] no other wallpaper in", dir);
            return;
        }
        apply(pool[Math.floor(Math.random() * pool.length)]);
    }

    function generateColors() {
        if (current === "")
            return;
        // both schemes are in the JSON: the light / dark mode doesn't need a run. `luminance` is
        // added: the wallpaper's mean perceived luminance (0…1, caelestia's ImageAnalyser formula),
        // which Colors.layer() uses to lift the translucent surfaces
        matugen.command = ["sh", "-c", `mkdir -p "$(dirname "$3")" && matugen image "$1" -t "$2" --source-color-index 0 --dry-run -j hex > "$3.tmp" || exit 1
l=$(magick "$1[0]" -resize '128x128>' -fx 'sqrt(0.299*r*r+0.587*g*g+0.114*b*b)' -format '%[fx:mean]' info: 2>/dev/null)
jq --argjson l "\${l:-0}" '. + {luminance: $l}' "$3.tmp" > "$3.tmp2" && mv -f "$3.tmp2" "$3.tmp"
mv -f "$3.tmp" "$3"`, "sh", current, Store.theme.scheme, colorsFile];
        matugen.running = false;
        matugen.running = true;
    }

    function cycleScheme(step: int) {
        const i = schemes.indexOf(Store.theme.scheme);
        Store.theme.scheme = schemes[(i + step + schemes.length) % schemes.length];
    }

    // regenerate colors when the scheme changes
    Connections {
        target: Store.theme
        function onSchemeChanged() {
            regenDebounce.restart();
        }
    }


    Timer {
        id: regenDebounce
        interval: 150
        onTriggered: root.generateColors()
    }

    Process {
        id: matugen
        stderr: StdioCollector {
            onStreamFinished: if (text.includes("rror"))
                console.warn("[Wallpapers] matugen:", text.trim())
        }
    }

    // list wallpapers
    Process {
        id: lister
        command: ["sh", "-c", 'find -L "$1" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \\) | sort', "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = text.split("\n").filter(l => l !== "");
                // reassigning an identical list would reset views bound to it
                if (JSON.stringify(list) !== JSON.stringify(root.list))
                    root.list = list;
                root.scanning = false;
                thumbnailer.generate();
            }
        }
    }

    // generate missing thumbnails; prints each new one so the grid can refresh
    Process {
        id: thumbnailer

        function generate() {
            if (running || root.list.length === 0)
                return;
            command = ["sh", "-c", `
                dir="$1"; shift
                mkdir -p "$dir"
                n=0
                for f; do
                    t="$dir/$(printf %s "$f" | md5sum | cut -c1-32).jpg"
                    [ -s "$t" ] && continue
                    vipsthumbnail "$f" -s 256x256 --smartcrop attention -o "$t[Q=85]" 2>/dev/null && n=$((n+1))
                    [ $((n % 4)) -eq 0 ] && echo tick
                done
                echo tick
            `, "sh", root.thumbDir, ...root.list];
            running = true;
        }

        stdout: SplitParser {
            onRead: root.thumbsVersion++
        }
    }

    // startup: Hyprland only starts awww-daemon; the shell sets the saved wallpaper once the
    // daemon answers (retrying while it starts). First run: adopt what awww is showing.
    property int queryTries: 0
    Process {
        id: queryCurrent
        running: Store.ready
        command: ["awww", "query"]
        stdout: StdioCollector {
            id: queryOut
        }
        onExited: code => {
            if (code !== 0) {
                if (root.queryTries++ < 15)
                    queryRetry.restart();
                return;
            }
            if (Store.wallpaper.current !== "") {
                Quickshell.execDetached(["awww", "img", Store.wallpaper.current, "--transition-type", "fade", "--transition-duration", "0.6"]);
            } else {
                const m = queryOut.text.match(/image: (.+)$/m);
                if (m)
                    Store.wallpaper.current = m[1].trim();
            }
            root.shown = Store.wallpaper.current;
            colorsCheck.running = true;
        }
    }

    Timer {
        id: queryRetry
        interval: 1000
        onTriggered: queryCurrent.running = true
    }

    Process {
        id: colorsCheck
        // no colors yet (first run, or only the old colors.json), or no luminance yet: generate them
        command: ["grep", "-q", "\"luminance\"", root.colorsFile]
        onExited: code => {
            if (code !== 0)
                root.generateColors();
        }
    }

    // list once the state is loaded, and again whenever the folder changes
    onDirChanged: if (Store.ready)
        refresh()
    Connections {
        target: Store
        function onReadyChanged() {
            if (Store.ready)
                root.refresh();
        }
    }
    Component.onCompleted: if (Store.ready)
        refresh()
}
