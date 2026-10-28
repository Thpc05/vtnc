import QtQuick
import qs.core
import qs.services
import qs.components
import qs.theme
import qs.kit as K
import qs.dwidgets.quick.panels
import qs.apps.common

// Clipboard (2026-10-17): the history cliphist keeps (services/Clipboard.qml), newest first, pinned ones
// on top. A row: its kind (text, link, image) and the text (Settings → Apps → Clipboard: 1 or 2 lines),
// or the image's thumbnail, size and dimensions; the current one grows with Copy · Pin · Delete. In the
// apps' look (K.Kit.appStyle; apps/common).
// Type to filter, ↑/↓ (or Tab) to move, Enter copies and closes, Del deletes, Ctrl+P pins,
// Ctrl+Shift+Del clears the history (twice: the button asks first).
FocusScope {
    id: root

    readonly property int lines: Store.appOptions.clipboard?.previewLines ?? 1
    readonly property int rowHeight: lines > 1 ? 60 : 48
    readonly property int imageRowHeight: 72
    readonly property int visibleItems: 6
    readonly property int actionsHeight: 32 + 8

    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        return q === "" ? Clipboard.entries : Clipboard.entries.filter(e => (e.image ? "image " + e.mime : e.text.toLowerCase()).includes(q));
    }
    readonly property var current: results[list.currentIndex] ?? null

    // Clear all asks first: a second press within 4 s wipes
    property bool confirmWipe: false
    Timer {
        id: wipeTimer
        interval: 4000
        onTriggered: root.confirmWipe = false
    }
    function wipe() {
        if (!confirmWipe) {
            confirmWipe = true;
            wipeTimer.restart();
            return;
        }
        confirmWipe = false;
        Clipboard.wipe();
    }

    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }
    readonly property FocusShape focusShape: FocusShape {}

    implicitWidth: 480
    implicitHeight: input.height + Tokens.spacing.s + rowHeight * visibleItems + actionsHeight

    HoverSelect {
        id: hover
    }

    function opened() {
        hover.reset();
        focusShape.reshuffle();
        confirmWipe = false;
        input.text = "";
        Clipboard.refresh();
        list.currentIndex = 0;
        list.positionViewAtBeginning();
        input.forceActiveFocus();
    }

    function copy(entry: var) {
        if (!entry)
            return;
        Runtime.closeApp();
        Clipboard.copy(entry);
    }

    // the kind of a text: a link, a path, or text
    function kindIcon(entry: var): string {
        if (!entry)
            return "notes";
        if (entry.image)
            return "image";
        const t = entry.text.trim();
        if (/^(https?|ftp):\/\//i.test(t))
            return "link";
        if (/^(~|\/)[^\s]*$/.test(t))
            return "folder";
        return "notes";
    }

    Row {
        id: bar
        width: parent.width
        height: 44
        spacing: Tokens.spacing.s

        K.SearchBar {
            id: input
            width: parent.width - wipeGroup.width - parent.spacing
            height: parent.height
            topPadding: 0
            bottomPadding: 0
            focus: true
            placeholderText: Clipboard.entries.length > 0 ? `Search ${Clipboard.entries.length} entries…` : "Search…"
            font: Qt.font({
                family: K.Kit.family,
                pixelSize: Tokens.font.normal,
                variableAxes: K.Kit.axes
            })

            onTextChanged: list.currentIndex = 0

            Keys.onPressed: e => {
                const ctrl = e.modifiers & Qt.ControlModifier;
                if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier)))
                    list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1);
                else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab)
                    list.currentIndex = Math.max(list.currentIndex - 1, 0);
                else if (e.key === Qt.Key_PageDown)
                    list.currentIndex = Math.min(list.currentIndex + root.visibleItems, list.count - 1);
                else if (e.key === Qt.Key_PageUp)
                    list.currentIndex = Math.max(list.currentIndex - root.visibleItems, 0);
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                    root.copy(root.current);
                else if (e.key === Qt.Key_Delete && ctrl && e.modifiers & Qt.ShiftModifier)
                    root.wipe();
                else if (e.key === Qt.Key_Delete && (input.text === "" || ctrl))
                    Clipboard.remove(root.current);
                else if (e.key === Qt.Key_P && ctrl && root.current)
                    Clipboard.setPinned(root.current, !Clipboard.isPinned(root.current));
                else
                    return;
                e.accepted = true;
            }
        }

        ActionGroup {
            id: wipeGroup
            width: root.confirmWipe ? 132 : 52
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            rowHeight: parent.height
            look: K.Kit.appLook
            actions: [
                root.confirmWipe ? {
                    text: "Clear all",
                    icon: "delete_sweep",
                    danger: true,
                    run: () => root.wipe()
                } : {
                    icon: "delete_sweep",
                    iconOnly: true,
                    enabled: Clipboard.entries.length > 0,
                    run: () => root.wipe()
                }
            ]
            Behavior on width {
                K.Anim {
                    type: K.Anim.FastSpatial
                }
            }
        }
    }

    ListView {
        id: list
        anchors.top: bar.bottom
        anchors.topMargin: Tokens.spacing.s
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        model: root.results
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: K.Kit.anim.durations.expressiveFastSpatial
        highlightMoveVelocity: -1
        highlightResizeDuration: K.Kit.anim.durations.expressiveFastSpatial
        highlightResizeVelocity: -1
        preferredHighlightBegin: 0
        preferredHighlightEnd: height
        highlightRangeMode: ListView.ApplyRange

        onCurrentIndexChanged: root.focusShape.next()

        highlight: RowHighlight {
            c: root.c
            focusShape: root.focusShape
            rowHeight: root.current?.image ? root.imageRowHeight : root.rowHeight
            iconX: Tokens.spacing.s + 16
            shapeSize: 40
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool pinned: Clipboard.pins.includes(modelData.id)
            readonly property int baseHeight: modelData.image ? root.imageRowHeight : root.rowHeight

            width: list.width
            height: baseHeight + (isCurrent ? root.actionsHeight : 0)
            clip: true
            Behavior on height {
                K.Anim {
                    type: K.Anim.FastSpatial
                }
            }

            // the kind (pinned: a pin)
            K.MaterialIcon {
                id: kind
                x: Tokens.spacing.s + 16 - width / 2
                y: Math.round((row.baseHeight - height) / 2)
                text: row.pinned ? "keep" : root.kindIcon(row.modelData)
                size: 20
                fill: row.isCurrent || row.pinned ? 1 : 0
                color: row.isCurrent && root.c.shapes ? root.c.overAccent : row.isCurrent || !root.c.shapes ? root.c.accent : root.c.weak
                Behavior on color {
                    K.CAnim {}
                }
            }

            // text
            K.StyledText {
                visible: !row.modelData.image
                anchors.left: parent.left
                anchors.leftMargin: Tokens.spacing.s + 32 + Tokens.spacing.m
                anchors.right: parent.right
                anchors.rightMargin: Tokens.spacing.m
                y: Math.round((row.baseHeight - height) / 2)
                // one line: the lines joined (not just the first)
                text: root.lines > 1 ? row.modelData.text : row.modelData.text.replace(/\s*\n+\s*/g, " ")
                textFormat: Text.PlainText
                wrapMode: root.lines > 1 ? Text.Wrap : Text.NoWrap
                maximumLineCount: root.lines
                elide: Text.ElideRight
                font.family: K.Kit.family
                font.variableAxes: K.Kit.axes
                font.pixelSize: 13
                color: row.isCurrent || root.c.shapes ? root.c.strong : root.c.weak
            }

            // image
            Rectangle {
                id: thumbBox
                visible: row.modelData.image
                x: Tokens.spacing.s + 32 + Tokens.spacing.m
                y: 8
                width: 96
                height: root.imageRowHeight - 16
                radius: K.Kit.rounding.small
                color: K.Kit.expressive.off
                clip: true

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize: Qt.size(192, 112)
                    source: {
                        Clipboard.thumbsVersion;
                        return row.modelData.image ? Clipboard.thumb(row.modelData) : "";
                    }
                }
            }
            Column {
                visible: row.modelData.image
                anchors.left: thumbBox.right
                anchors.leftMargin: Tokens.spacing.m
                anchors.right: parent.right
                anchors.rightMargin: Tokens.spacing.m
                anchors.verticalCenter: thumbBox.verticalCenter
                spacing: 1

                K.StyledText {
                    width: parent.width
                    text: "Image · " + (row.modelData.mime ?? "").toUpperCase()
                    elide: Text.ElideRight
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: row.isCurrent || root.c.shapes ? root.c.strong : root.c.weak
                }
                K.StyledText {
                    width: parent.width
                    text: (row.modelData.dims ?? "") + "  ·  " + (row.modelData.size ?? "")
                    elide: Text.ElideRight
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 12
                    color: root.c.weak
                }
            }

            K.StateLayer {
                id: mouse
                radius: K.Kit.rounding.large
                color: root.c.strong
                stateOpacity: containsMouse && !row.isCurrent ? 0.08 : 0
                onPositionChanged: m => hover.moved(mouse, m, () => list.currentIndex = row.index)
                onClicked: root.copy(row.modelData)
            }

            ActionGroup {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.spacing.s + 32 + Tokens.spacing.m
                anchors.right: parent.right
                anchors.rightMargin: Tokens.spacing.s
                y: row.baseHeight
                visible: opacity > 0
                opacity: row.isCurrent ? 1 : 0
                look: K.Kit.appLook
                idleFill: root.c.shapes ? K.Kit.expressive.high : root.c.off
                actions: row.isCurrent ? [
                    {
                        text: "Copy",
                        icon: "content_copy",
                        primary: true,
                        run: () => root.copy(row.modelData)
                    },
                    {
                        text: row.pinned ? "Unpin" : "Pin",
                        icon: "keep",
                        run: () => Clipboard.setPinned(row.modelData, !row.pinned)
                    },
                    {
                        text: "Delete",
                        icon: "delete",
                        run: () => Clipboard.remove(row.modelData)
                    }
                ] : []
                Behavior on opacity {
                    K.Anim {
                        type: K.Anim.FastEffects
                    }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            visible: list.count === 0 && !Clipboard.loading
            spacing: 6

            K.MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "content_paste_off"
                size: 32
                color: root.c.weak
            }
            K.StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Clipboard.entries.length === 0 ? "Nothing copied yet" : "No matches"
                font.family: K.Kit.family
                font.variableAxes: K.Kit.axes
                font.pixelSize: 13
                color: root.c.weak
            }
        }
    }
}
