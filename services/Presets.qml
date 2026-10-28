pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Presets (core/STATE.md): snapshots of the shell's style, i.e. island.json, dashboard.json and
// appearance.json (which holds the wallpaper, scheme, light mode and color mapping). One file each:
// ~/.config/vtnc/presets/<name>.json = { name, created, updated, config: { island, dashboard, appearance } }.
// Store.presets.active is the one applied or saved last ("" = none); changing a setting makes it
// modified until it's saved (only on the Presets page) or reverted. A preset is
// saved with or without the wallpaper; without one (or when its file is gone) it keeps the one shown.
Singleton {
    id: root

    readonly property var parts: ["island", "dashboard", "appearance"]
    // the preset that can't be saved over, renamed or deleted (the user's base)
    readonly property string lockedName: "Default"
    readonly property var partTitles: ({
            island: "Island",
            dashboard: "Dashboard",
            appearance: "Appearance"
        })

    // the user's presets, by name: [{ name, file, created, updated, config }]
    property var saved: []
    // the presets folder was read at least once
    property bool loaded: false
    // presets' wallpapers whose file is gone
    property var missing: []
    // the last apply kept the shown wallpaper because the preset's was gone ("" = no)
    property string lastMissing: ""
    readonly property var list: saved

    // null when none is active (or its file is gone): then nothing is modified
    readonly property var activePreset: find(Store.presets.active)
    readonly property string active: activePreset?.name ?? ""

    // what the files hold now
    readonly property var current: ({
            island: Store.files.island.json,
            dashboard: Store.files.dashboard.json,
            appearance: Store.files.appearance.json
        })

    // the parts that differ from the active preset
    readonly property var modifiedParts: {
        if (!Store.ready || !loaded || !activePreset)
            return [];
        const p = configOf(activePreset);
        return parts.filter(part => current[part] && Store.files[part].signature(current[part]) !== Store.files[part].signature(p[part]));
    }
    readonly property bool modified: modifiedParts.length > 0

    function isLocked(preset): bool {
        return (preset?.name ?? "") === lockedName;
    }

    function find(name: string): var {
        return list.find(p => p.name === name) ?? null;
    }

    // the wallpaper a preset was saved with ("" = none: it keeps the one shown)
    function wallpaperOf(preset): string {
        return preset?.config?.appearance?.wallpaper?.current ?? "";
    }
    function wallpaperMissing(preset): bool {
        return missing.includes(wallpaperOf(preset));
    }

    // a preset's config as it applies: a part it lacks is the factory one; no wallpaper, or one whose
    // file is gone, keeps the one shown
    function configOf(preset): var {
        const out = {};
        for (const part of parts)
            out[part] = preset?.config?.[part] ?? Store.files[part].defaults;
        const wp = out.appearance.wallpaper?.current ?? "";
        if (wp === "" || missing.includes(wp)) {
            out.appearance = Object.assign({}, out.appearance, {
                wallpaper: {
                    current: Store.wallpaper.current
                }
            });
        }
        return out;
    }

    // "" when `name` can be a new preset's name, else why not
    function nameError(name: string, except: string): string {
        const n = name.trim();
        if (n === "")
            return "Enter a name";
        if (list.some(p => p.name !== except && (p.name.toLowerCase() === n.toLowerCase() || p.file === fileFor(n))))
            return "A preset with this name exists";
        return "";
    }

    function fileFor(name: string): string {
        return Store.presetsDir + "/" + name.trim().replace(/\//g, "-").replace(/^\.+/, "") + ".json";
    }

    // its wallpaper's file is checked first (a gone one keeps the wallpaper shown)
    function apply(name: string): bool {
        const preset = find(name);
        if (!preset)
            return false;
        const wp = wallpaperOf(preset);
        if (wp === "") {
            applyNow(preset);
            return true;
        }
        checker.preset = preset.name;
        checker.path = wp;
        checker.running = true;
        return true;
    }

    function applyNow(preset) {
        if (!preset)
            return;
        lastMissing = wallpaperMissing(preset) ? wallpaperOf(preset) : "";
        const config = configOf(preset);
        for (const part of parts)
            replacePart(part, config[part]);
        Store.presets.active = preset.name;
        return true;
    }

    // from an open app (the Presets page): the app closes first, then `name` applies on the idle island
    // (the callback lives here: the page may be gone by then)
    // The wallpaper doesn't wait for the close: it starts changing (if its file exists)
    // `wallpaperDelay` ms after the click, closer to the shell's color change (matugen).
    function applyAfterClose(name: string) {
        const wp = wallpaperOf(find(name));
        if (wp !== "" && wp !== Store.wallpaper.current) {
            early.path = wp;
            early.running = true;
        }
        Runtime.closeThen(() => root.apply(name));
    }
    function revertAfterClose() {
        Runtime.closeThen(() => root.revert(""));
    }

    // the active preset's `part` (or every part) back
    function revert(part: string) {
        if (!activePreset)
            return;
        const config = configOf(activePreset);
        for (const p of (part ? [part] : parts))
            replacePart(p, config[p]);
    }

    function replacePart(part: string, obj) {
        if (current[part] && Store.files[part].signature(current[part]) === Store.files[part].signature(obj))
            return;
        Store.files[part].replace(obj);
    }

    // the files as they are now, into the active preset, with a wallpaper if it had one
    function save(): bool {
        if (!activePreset || isLocked(activePreset))
            return false;
        write(activePreset.file, {
            name: activePreset.name,
            created: activePreset.created ?? now(),
            updated: now(),
            config: snapshot(wallpaperOf(activePreset) !== "")
        });
        return true;
    }

    // the files as they are now, into a new preset, which becomes the active one; "" or the error
    function saveAs(name: string, withWallpaper: bool): string {
        const error = nameError(name, "");
        if (error !== "")
            return error;
        const n = name.trim();
        write(fileFor(n), {
            name: n,
            created: now(),
            updated: now(),
            config: snapshot(withWallpaper)
        });
        Store.presets.active = n;
        return "";
    }

    function rename(name: string, newName: string): string {
        const preset = find(name);
        if (!preset || isLocked(preset))
            return "";
        const error = nameError(newName, name);
        if (error !== "")
            return error;
        const n = newName.trim();
        const file = fileFor(n);
        const text = JSON.stringify(Object.assign({}, fileContent(preset), {
            name: n
        }), null, 2) + "\n";
        run(["sh", "-c", 'printf "%s" "$3" > "$2.tmp" && mv "$2.tmp" "$2" && { [ "$1" = "$2" ] || rm -f "$1"; }', "sh", preset.file, file, text]);
        if (active === name)
            Store.presets.active = n;
        return "";
    }

    function duplicate(name: string) {
        const preset = find(name);
        if (!preset)
            return;
        let n = preset.name + " copy";
        for (let i = 2; nameError(n, "") !== ""; i++)
            n = `${preset.name} copy ${i}`;
        write(fileFor(n), {
            name: n,
            created: now(),
            updated: now(),
            config: preset.config
        });
    }

    // the active one removed: none is active (nothing is applied)
    function remove(name: string) {
        const preset = find(name);
        if (!preset || isLocked(preset))
            return;
        run(["rm", "-f", preset.file]);
        if (active === name)
            Store.presets.active = "";
    }

    function scan() {
        if (Store.presetsDir !== "")
            scanner.running = true;
    }

    function snapshot(withWallpaper: bool): var {
        const s = JSON.parse(JSON.stringify(current));
        if (!withWallpaper && s.appearance)
            s.appearance.wallpaper = {
                current: ""
            };
        return s;
    }

    function fileContent(preset): var {
        return {
            name: preset.name,
            created: preset.created,
            updated: preset.updated,
            config: preset.config
        };
    }

    function now(): string {
        return new Date().toISOString();
    }

    function write(file: string, content) {
        run(["sh", "-c", 'printf "%s" "$2" > "$1.tmp" && mv "$1.tmp" "$1"', "sh", file, JSON.stringify(content, null, 2) + "\n"]);
    }

    // file operations run one at a time; the list is read again after them
    property var queue: []

    function run(command) {
        queue = queue.concat([command]);
        next();
    }

    function next() {
        if (op.running)
            return;
        if (queue.length === 0) {
            scan();
            return;
        }
        op.command = queue[0];
        queue = queue.slice(1);
        op.running = true;
    }

    Process {
        id: op
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "")
                console.warn("[Presets]", text.trim())
        }
        onExited: Qt.callLater(root.next)
    }

    // every presets/*.json as "\x1e<path>\x1f<content>"
    Process {
        id: scanner
        command: ["sh", "-c", 'for f in "$1"/*.json; do [ -f "$f" ] || continue; printf "\\036%s\\037" "$f"; cat "$f"; done', "sh", Store.presetsDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const chunk of text.split("\x1e")) {
                    const i = chunk.indexOf("\x1f");
                    if (i < 0)
                        continue;
                    const file = chunk.slice(0, i);
                    try {
                        const j = JSON.parse(chunk.slice(i + 1));
                        const name = typeof j.name === "string" && j.name.trim() !== "" ? j.name.trim() : file.split("/").pop().replace(/\.json$/, "");
                        if (out.some(p => p.name === name))
                            continue;
                        out.push({
                            name: name,
                            file: file,
                            created: j.created,
                            updated: j.updated,
                            config: typeof j.config === "object" && j.config ? j.config : {}
                        });
                    } catch (e) {
                        console.warn("[Presets] not valid JSON:", file, e);
                    }
                }
                out.sort((a, b) => a.name.localeCompare(b.name));
                root.saved = out;
                const paths = out.map(p => root.wallpaperOf(p)).filter(p => p !== "");
                if (paths.length > 0) {
                    missingCheck.command = ["sh", "-c", 'for f; do [ -f "$f" ] || printf "%s\\n" "$f"; done', "sh", ...paths];
                    missingCheck.running = true;
                } else {
                    root.missing = [];
                    root.loaded = true;
                }
            }
        }
    }

    // the presets' wallpapers that are gone
    Process {
        id: missingCheck
        stdout: StdioCollector {
            onStreamFinished: {
                root.missing = text.split("\n").filter(l => l !== "");
                root.loaded = true;
            }
        }
    }

    // applyAfterClose(): the wallpaper after `wallpaperDelay`, when its file exists
    property int wallpaperDelay: 250
    Process {
        id: early
        property string path
        command: ["test", "-f", path]
        onExited: code => {
            if (code === 0)
                earlyTimer.restart();
        }
    }
    Timer {
        id: earlyTimer
        interval: root.wallpaperDelay
        onTriggered: Wallpapers.apply(early.path)
    }

    // apply(): does the preset's wallpaper still exist
    Process {
        id: checker
        property string preset
        property string path
        command: ["test", "-f", path]
        onExited: code => {
            const others = root.missing.filter(p => p !== path);
            root.missing = code === 0 ? others : others.concat([path]);
            root.applyNow(root.find(preset));
        }
    }

    Connections {
        target: Store
        function onReadyChanged() {
            if (Store.ready)
                root.scan();
        }
    }
    Component.onCompleted: if (Store.ready)
        scan()
}
