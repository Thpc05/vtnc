import QtQuick
import qs.core
import qs.apps.notes

// The Notes summary's data (2026-10-17): the notes on disk (pinned first, then the newest), read again
// each time the dashboard opens. A click opens that note in Notes; + opens it on a new one.
QtObject {
    id: root

    readonly property string title: "Notes"
    readonly property string icon: "sticky_note_2"
    readonly property string empty: "No notes"
    // the header's action (an icon)
    readonly property string action: "add"

    readonly property NoteFiles files: NoteFiles {}
    Component.onCompleted: files.refresh()

    readonly property int count: files.notes.length
    readonly property string countText: count === 1 ? "1 note" : `${count} notes`
    readonly property var items: files.notes.slice(0, 24).map(n => ({
                key: n.file,
                lead: "description",
                image: "",
                title: n.title || "Untitled",
                sub: "",
                time: age(n.mtime),
                pinned: files.isPinned(n.file),
                file: n.file
            }))

    function age(mtime: real): string {
        const d = new Date(mtime * 1000);
        const now = new Date();
        if (d.toDateString() === now.toDateString())
            return Qt.formatTime(d, "hh:mm");
        return Qt.locale().monthName(d.getMonth(), Locale.ShortFormat) + " " + d.getDate();
    }

    function opened() {
        files.refresh();
    }
    function openApp() {
        Runtime.openApp("notes", {});
    }
    function activate(item: var) {
        Runtime.openApp("notes", {
            file: item.file
        });
    }
    function run() {
        Runtime.openApp("notes", {
            new: true
        });
    }
}
