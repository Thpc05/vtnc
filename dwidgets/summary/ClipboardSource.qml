import QtQuick
import qs.core
import qs.services

// The Clipboard summary's data (2026-10-17): the history (pinned first). A click copies the entry back
// (a check on its row for a moment).
QtObject {
    id: root

    readonly property string title: "Clipboard"
    readonly property string icon: "content_paste"
    readonly property string empty: "Clipboard is empty"
    readonly property string action: ""

    readonly property int count: Clipboard.entries.length
    readonly property string countText: count === 1 ? "1 item" : `${count} items`
    readonly property var items: {
        void Clipboard.thumbsVersion;
        return Clipboard.entries.slice(0, 24).map(e => ({
                    key: e.id,
                    lead: kindIcon(e),
                    image: e.image ? Clipboard.thumb(e) : "",
                    picture: e.image,
                    title: e.image ? "Image" : e.text.replace(/\s+/g, " ").trim(),
                    sub: e.image ? `${e.dims} · ${e.size}` : "",
                    time: "",
                    pinned: Clipboard.isPinned(e),
                    entry: e
                }));
    }
    // the row just copied (its key), for a moment
    property string done: ""
    readonly property Timer doneTimer: Timer {
        interval: 1200
        onTriggered: root.done = ""
    }

    function kindIcon(e: var): string {
        if (e.image)
            return "image";
        const t = e.text.trim();
        if (/^(https?|ftp):\/\//i.test(t))
            return "link";
        if (/^(~|\/)[^\s]*$/.test(t))
            return "folder";
        return "notes";
    }

    function opened() {
        Clipboard.refresh();
    }
    function openApp() {
        Runtime.openApp("clipboard", {});
    }
    function activate(item: var) {
        Clipboard.copy(item.entry);
        done = item.key;
        doneTimer.restart();
    }
    function run() {
    }
}
