import QtQuick
import Quickshell
import Quickshell.Io
import "StateMerge.js" as Merge

// One of the shell's JSON files (core/STATE.md): its `adapter` (the JsonAdapter the Store aliases)
// is loaded from `path`, validated against `factoryPath` (StateMerge), completed and saved back.
// `path` stays "" until the Store's bootstrap has created the directories (and migrated).
Scope {
    id: root

    property string path: ""
    property string factoryPath
    property JsonAdapter adapter

    // true once the file was loaded and validated at least once
    property bool ready: false
    // the file's last validated content (what Presets compares and saves)
    property var json: null

    readonly property var defaults: {
        try {
            return JSON.parse(factory.text());
        } catch (e) {
            console.error("[Store] factory defaults are invalid:", root.factoryPath, e);
            return {};
        }
    }

    function save() {
        saveTimer.stop();
        writeNow();
    }

    // Our own writes also trigger the file watcher. Reloading then would put the file's
    // (older) values back into memory and undo edits made in the meantime, so the
    // watcher ignores changes shortly after we wrote.
    property real lastSelfWrite: 0

    function writeNow() {
        lastSelfWrite = Date.now();
        file.writeAdapter();
    }

    // `obj` completed / fixed from the defaults
    function merged(obj) {
        return Merge.merge(obj, defaults);
    }

    // `obj` as this file would hold it, as a canonical string (Presets compares these)
    function signature(obj): string {
        const m = Merge.known(merged(obj), defaults);
        delete m.version;
        return Merge.canonical(m);
    }

    // replace the whole content (merged with the defaults), as if the file had been edited
    function replace(obj) {
        saveTimer.stop();
        file.setText(JSON.stringify(merged(obj), null, 2) + "\n");
    }

    function resetToFactory() {
        saveTimer.stop();
        file.setText(factory.text());
    }

    // the load handlers' own rewrites (a fix-up, the factory text): a setText inside the FileView's
    // load is dropped mid-operation (the file is written, but neither the text nor the adapter
    // change), so it runs after it; its echo is skipped and onSaved validates the new content
    property bool rewriting: false

    function rewrite(text: string) {
        saveTimer.stop();
        rewriting = true;
        Qt.callLater(() => {
            lastSelfWrite = Date.now();
            file.setText(text);
        });
    }

    function validate() {
        let parsed;
        try {
            parsed = JSON.parse(file.text());
        } catch (e) {
            if (root.ready) {
                console.warn("[Store]", root.path, "is not valid JSON, keeping current values:", e);
                return;
            }
            console.warn("[Store]", root.path, "is not valid JSON, backing up and restoring defaults:", e);
            // the factory text only once the copy is done, so the .bak keeps the broken file
            backup.exec(["cp", "-f", root.path, root.path + ".bak"]);
            return;
        }

        const merged = Merge.merge(parsed, root.defaults);
        if (Merge.canonical(merged) !== Merge.canonical(parsed)) {
            console.info("[Store] completing/fixing", root.path, "from defaults");
            root.rewrite(JSON.stringify(merged, null, 2) + "\n");
            return;
        }
        root.json = parsed;
        root.ready = true;
    }

    Process {
        id: backup
        onExited: root.rewrite(factory.text())
    }

    FileView {
        id: factory
        path: root.factoryPath
        blockLoading: true
    }

    // JsonAdapter doesn't report reassigned `var` properties inside nested JsonObjects
    // (the widgets arrays): the Store calls this for them
    function changed() {
        if (!file.loading && root.ready)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: root.writeNow()
    }

    FileView {
        id: file

        path: root.path
        adapter: root.adapter
        watchChanges: true
        atomicWrites: true
        printErrors: false

        property bool loading: true

        onFileChanged: {
            if (Date.now() - root.lastSelfWrite < 1500)
                return;
            loading = true;
            reload();
        }
        onLoaded: {
            root.validate();
            Qt.callLater(() => loading = false);
        }
        onSaved: {
            if (root.rewriting) {
                root.rewriting = false;
                root.validate();
                return;
            }
            try {
                root.json = JSON.parse(text());
            } catch (e) {}
        }
        onLoadFailed: err => {
            // once loaded, a missing file (deleted, or caught mid atomic write) is recreated
            // from memory instead of being reset to the factory defaults
            if (err === FileViewError.FileNotFound && root.ready)
                root.writeNow();
            else if (err === FileViewError.FileNotFound)
                root.rewrite(factory.text());
            else
                console.error("[Store] failed to load", root.path, FileViewError.toString(err));
        }
        onAdapterUpdated: root.changed()
    }
}
