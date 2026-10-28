import QtQuick
import Quickshell.Io
import qs.core
import qs.components
import qs.theme
import qs.kit as K
import qs.dwidgets.quick.panels
import qs.apps.common

// Notes (2026-10-17): the notes at the left (search, New, pinned first; NoteFiles.qml), the open one at
// the right: a plain text editor that saves itself 500 ms after typing stops (and on closing), or its
// Markdown rendered (Preview; Settings → Apps → Notes: Format markdown / plain, the editor's font and
// size, the folder, opening on the preview). A note's title is its first line. In the apps' look
// (K.Kit.appStyle; apps/common).
// Keys: Ctrl+N new, Ctrl+P preview, Ctrl+F search, Ctrl+↑/↓ the previous / next note, Esc closes.
FocusScope {
    id: root

    readonly property var cfg: Store.appOptions.notes
    readonly property bool markdown: (cfg?.format ?? "markdown") === "markdown"
    readonly property int listWidth: 220
    readonly property int rowHeight: 48

    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }
    readonly property FocusShape focusShape: FocusShape {}
    readonly property NoteFiles files: NoteFiles {}

    readonly property var results: {
        const q = search.text.trim().toLowerCase();
        return q === "" ? files.notes : files.notes.filter(n => n.title.toLowerCase().includes(q));
    }
    // the list marks the open note (the files arrive after it opened); later: the ListView's model reset
    // puts its index back to 0 after this handler
    onResultsChanged: Qt.callLater(syncIndex)
    function syncIndex() {
        list.currentIndex = results.findIndex(n => n.file === openFile);
    }
    // the open note's file ("" = none)
    property string openFile: ""
    property bool preview: false
    // the editor's text came from the file (no save until it's typed in)
    property bool loading: false
    property bool dirty: false
    property bool confirmDelete: false

    implicitWidth: 720
    implicitHeight: 440

    // args (the dashboard's Notes summary): { file } opens that note, { new: true } a new one
    function opened(args) {
        focusShape.reshuffle();
        files.refresh();
        preview = markdown && (cfg?.openPreview ?? false);
        confirmDelete = false;
        if (args?.new) {
            newNote();
            return;
        }
        const last = args?.file || Store.appGet("notes", "last", "");
        if (last !== "" && last !== openFile)
            open(last);
        editor.forceActiveFocus();
    }
    function closed() {
        saveNow();
    }

    function open(file: string) {
        if (file === openFile)
            return;
        saveNow();
        confirmDelete = false;
        openFile = file;
        Store.appSet("notes", "last", file);
        syncIndex();
    }

    function newNote() {
        search.text = "";
        open(files.create());
        preview = false;
        editor.text = "";
        editor.forceActiveFocus();
    }

    function deleteNote() {
        if (openFile === "")
            return;
        if (!confirmDelete) {
            confirmDelete = true;
            return;
        }
        const gone = openFile;
        openFile = "";
        files.remove(gone);
        Store.appSet("notes", "last", "");
        confirmDelete = false;
        editor.text = "";
    }

    function step(dir: int) {
        const i = results.findIndex(n => n.file === openFile);
        const next = results[Math.max(0, Math.min(results.length - 1, i + dir))];
        if (next)
            open(next.file);
    }

    function styledLinks(md: string): string {
        const hex = String(c.accent);
        return md.replace(/(^|[^!])\[([^\]]+)\]\(([^)\s]+)\)/g, (m, pre, label, url) => `${pre}<a href="${url}"><font color="${hex}">${label}</font></a>`);
    }

    function saveNow() {
        saveTimer.stop();
        if (!dirty || openFile === "")
            return;
        noteFile.setText(editor.text);
        files.touched(openFile, editor.text);
        dirty = false;
    }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: root.saveNow()
    }

    FileView {
        id: noteFile
        path: root.openFile !== "" ? root.files.path(root.openFile) : ""
        printErrors: false
        onLoaded: {
            root.loading = true;
            editor.text = text();
            root.loading = false;
            root.dirty = false;
        }
        onLoadFailed: {
            root.loading = true;
            editor.text = "";
            root.loading = false;
        }
    }

    Keys.onPressed: e => {
        if (!(e.modifiers & Qt.ControlModifier))
            return;
        if (e.key === Qt.Key_N)
            newNote();
        else if (e.key === Qt.Key_P && markdown)
            preview = !preview;
        else if (e.key === Qt.Key_F)
            search.forceActiveFocus();
        else if (e.key === Qt.Key_Down)
            step(1);
        else if (e.key === Qt.Key_Up)
            step(-1);
        else
            return;
        e.accepted = true;
    }

    HoverSelect {
        id: hover
    }

    // the list ----------------------------------------------------------------
    Item {
        id: side
        width: root.listWidth
        height: parent.height

        K.SearchBar {
            id: search
            width: parent.width - newGroup.width - Tokens.spacing.s
            height: 40
            topPadding: 0
            bottomPadding: 0
            placeholderText: "Search notes…"
            font: Qt.font({
                family: K.Kit.family,
                pixelSize: Tokens.font.normal,
                variableAxes: K.Kit.axes
            })
            onTextChanged: {
                const i = root.results.findIndex(n => n.file === root.openFile);
                list.currentIndex = i;
            }
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Down || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    if (root.results.length > 0)
                        root.open(root.results[0].file);
                    editor.forceActiveFocus();
                    e.accepted = true;
                }
            }
        }

        ActionGroup {
            id: newGroup
            anchors.right: parent.right
            width: 48
            rowHeight: 40
            look: K.Kit.appLook
            actions: [
                {
                    icon: "add",
                    iconOnly: true,
                    primary: true,
                    run: () => root.newNote()
                }
            ]
        }

        ListView {
            id: list
            anchors.top: search.bottom
            anchors.topMargin: Tokens.spacing.s
            anchors.bottom: parent.bottom
            width: parent.width
            clip: true
            model: root.results
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: K.Kit.anim.durations.expressiveFastSpatial
            highlightMoveVelocity: -1
            highlightFollowsCurrentItem: true

            onCurrentIndexChanged: root.focusShape.next()

            highlight: RowHighlight {
                c: root.c
                focusShape: root.focusShape
                rowHeight: root.rowHeight
                iconX: Tokens.spacing.s + 12
                shapeSize: 32
            }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool isCurrent: modelData.file === root.openFile
                readonly property bool pinned: root.files.pins.includes(modelData.file)

                width: list.width
                height: root.rowHeight

                K.MaterialIcon {
                    x: Tokens.spacing.s + 12 - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.pinned ? "keep" : "description"
                    size: 18
                    fill: row.isCurrent ? 1 : 0
                    color: row.isCurrent && root.c.shapes ? root.c.overAccent : row.isCurrent || !root.c.shapes ? root.c.accent : root.c.weak
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.spacing.s + 24 + Tokens.spacing.s
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.spacing.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    K.StyledText {
                        width: parent.width
                        text: row.modelData.title || "Untitled"
                        elide: Text.ElideRight
                        font.family: K.Kit.family
                        font.variableAxes: K.Kit.axes
                        font.pixelSize: 13
                        font.weight: row.isCurrent && root.c.kind === "tone" ? Font.Bold : Font.Medium
                        color: row.isCurrent || root.c.shapes ? root.c.strong : root.c.weak
                    }
                    K.StyledText {
                        width: parent.width
                        text: {
                            const d = new Date(row.modelData.mtime * 1000);
                            return d.toDateString() === new Date().toDateString() ? Qt.formatTime(d, "hh:mm") : Qt.formatDate(d, "d MMM yyyy");
                        }
                        font.family: K.Kit.family
                        font.variableAxes: K.Kit.axes
                        font.pixelSize: 11
                        color: root.c.weak
                    }
                }

                K.StateLayer {
                    id: mouse
                    radius: K.Kit.rounding.large
                    color: root.c.strong
                    stateOpacity: containsMouse && !row.isCurrent ? 0.08 : 0
                    onClicked: {
                        root.open(row.modelData.file);
                        editor.forceActiveFocus();
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: list.count === 0
                spacing: 6

                K.MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "sticky_note_2"
                    size: 28
                    color: root.c.weak
                }
                K.StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.files.notes.length === 0 ? "No notes yet" : "No matches"
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 13
                    color: root.c.weak
                }
            }
        }
    }

    // the note ----------------------------------------------------------------
    Item {
        id: page
        anchors.left: side.right
        anchors.leftMargin: Tokens.spacing.m
        anchors.right: parent.right
        height: parent.height

        // its title (the first line) and buttons
        Item {
            id: noteBar
            width: parent.width
            height: 40

            K.StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.right: noteActions.left
                anchors.rightMargin: Tokens.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                text: root.openFile === "" ? "Notes" : ((editor.text.split("\n")[0] ?? "").replace(/^#+\s*/, "").trim() || "Untitled")
                elide: Text.ElideRight
                font.family: K.Kit.family
                font.variableAxes: K.Kit.axes
                font.pixelSize: 17
                font.weight: Font.Bold
                color: root.c.strong
            }

            ActionGroup {
                id: noteActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.openFile !== ""
                // the icon-only buttons are 40 wide, 2 apart; the confirm grows to fit its label
                width: root.confirmDelete ? (root.markdown ? 2 * 40 + 2 * 2 + 116 : 40 + 2 + 116) : root.markdown ? 3 * 40 + 2 * 2 : 2 * 40 + 2
                look: K.Kit.appLook
                actions: {
                    const out = [];
                    if (root.markdown)
                        out.push({
                            icon: root.preview ? "edit" : "visibility",
                            iconOnly: true,
                            primary: root.preview,
                            run: () => root.preview = !root.preview
                        });
                    out.push({
                        icon: "keep",
                        iconOnly: true,
                        primary: root.files.isPinned(root.openFile),
                        run: () => root.files.setPinned(root.openFile, !root.files.isPinned(root.openFile))
                    });
                    out.push(root.confirmDelete ? {
                        text: "Delete note",
                        icon: "delete",
                        danger: true,
                        run: () => root.deleteNote()
                    } : {
                        icon: "delete",
                        iconOnly: true,
                        run: () => root.deleteNote()
                    });
                    return out;
                }
                Behavior on width {
                    K.Anim {
                        type: K.Anim.FastSpatial
                    }
                }
            }
        }

        // the sheet: the container (Shapes), a tint (Two tones), a hairline frame (Tone)
        Rectangle {
            id: sheet
            anchors.top: noteBar.bottom
            anchors.topMargin: Tokens.spacing.s
            anchors.bottom: parent.bottom
            width: parent.width
            radius: K.Kit.rounding.large
            color: root.c.shapes ? K.Kit.expressive.container : root.c.kind === "tones" ? Qt.tint(K.Kit.expressive.container, Qt.alpha(root.c.accent, K.Kit.expressive.light ? 0.10 : 0.08)) : "transparent"
            border.width: root.c.kind === "tone" ? 1 : 0
            border.color: Qt.alpha(root.c.accent, 0.25)

            // the editor
            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: Tokens.spacing.m
                visible: !root.preview && root.openFile !== ""
                clip: true
                contentWidth: width
                contentHeight: editor.contentHeight
                boundsBehavior: Flickable.StopAtBounds

                function ensureVisible(r) {
                    if (contentY >= r.y)
                        contentY = r.y;
                    else if (contentY + height <= r.y + r.height)
                        contentY = r.y + r.height - height;
                }

                TextEdit {
                    id: editor
                    width: flick.width
                    height: Math.max(flick.height, contentHeight)
                    focus: true
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    selectByMouse: true
                    persistentSelection: true
                    font.family: root.cfg?.font === "mono" ? K.Kit.monoFamily : K.Kit.family
                    font.pixelSize: root.cfg?.fontSize || 14
                    color: root.c.strong
                    selectionColor: Qt.alpha(root.c.accent, 0.35)
                    selectedTextColor: root.c.strong
                    renderType: Tokens.font.renderType
                    onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
                    onTextChanged: if (!root.loading && root.openFile !== "") {
                        root.dirty = true;
                        saveTimer.restart();
                    }

                    K.StyledText {
                        visible: editor.text === ""
                        text: root.markdown ? "Title on the first line, then Markdown…" : "Title on the first line…"
                        font: editor.font
                        color: root.c.weak
                    }
                }
            }

            // the preview
            Flickable {
                anchors.fill: parent
                anchors.margins: Tokens.spacing.m
                visible: root.preview && root.openFile !== ""
                clip: true
                contentWidth: width
                contentHeight: rendered.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Text {
                    id: rendered
                    width: parent.width
                    // links in the accent (Qt's Markdown ignores linkColor): [text](url) as a coloured anchor
                    text: root.preview ? root.styledLinks(editor.text) : ""
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                    font.family: K.Kit.family
                    font.pixelSize: root.cfg?.fontSize || 14
                    color: root.c.strong
                    linkColor: root.c.accent
                    renderType: Tokens.font.renderType
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }

            // nothing open
            Column {
                anchors.centerIn: parent
                visible: root.openFile === ""
                spacing: 8

                K.StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Pick a note or start a new one"
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 13
                    color: root.c.weak
                }
                ActionGroup {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 140
                    look: K.Kit.appLook
                    actions: [
                        {
                            text: "New note",
                            icon: "add",
                            primary: true,
                            run: () => root.newNote()
                        }
                    ]
                }
            }
        }
    }
}
