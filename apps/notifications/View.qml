import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.services
import qs.components
import qs.theme
import qs.kit as K
import qs.dwidgets.quick.panels
import qs.apps.common

// Notifications (2026-10-17): the history (services/Notifications.qml), newest first, grouped by app
// (Settings → Apps → Notifications: groupByApp; a group's header folds it). A row: the app's icon, the
// summary, the body's first line and its age; the current one grows to the whole body and its buttons:
// the app's actions while the app still holds it, and Dismiss. On top: the count, Do not disturb and
// Clear all. In the apps' look (K.Kit.appStyle; apps/common).
// Keys: ↑/↓ move, Enter runs the card's click (its default action) or folds a group, Del dismisses,
// Shift+Del clears the current app's group.
FocusScope {
    id: root

    readonly property int rowHeight: 56
    readonly property int headerHeight: 32
    readonly property int visibleHeight: 400
    // the rows' ages ("now", "5m"…), redrawn every minute while the app is shown
    property int minute: 0
    Timer {
        interval: 60000
        repeat: true
        running: root.visible
        onTriggered: root.minute++
    }

    readonly property bool grouped: Store.appOptions.notifications?.groupByApp ?? true

    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }
    readonly property FocusShape focusShape: FocusShape {}

    // folded groups (by app name)
    property var folded: ({})

    // the rows: { kind: "header", app, count } / { kind: "entry", entry }, newest first; grouped, the
    // groups in the order of their newest notification
    readonly property var rows: {
        const all = Notifications.list.slice().reverse();
        if (!grouped)
            return all.map(e => ({
                        kind: "entry",
                        entry: e
                    }));
        const order = [];
        const groups = {};
        for (const e of all) {
            const app = e.appName || "Other";
            if (!groups[app]) {
                groups[app] = [];
                order.push(app);
            }
            groups[app].push(e);
        }
        const out = [];
        for (const app of order) {
            out.push({
                kind: "header",
                app: app,
                count: groups[app].length
            });
            if (!folded[app])
                for (const e of groups[app])
                    out.push({
                        kind: "entry",
                        entry: e
                    });
        }
        return out;
    }
    readonly property var current: rows[list.currentIndex] ?? null

    implicitWidth: 480
    implicitHeight: header.height + Tokens.spacing.s + visibleHeight

    // args (the dashboard's Notifications summary): { id } makes that notification current (its group unfolded)
    function opened(args) {
        focusShape.reshuffle();
        const id = args?.id ?? -1;
        const target = Notifications.list.find(e => e.id === id);
        if (target && folded[target.appName || "Other"])
            fold(target.appName || "Other");
        const at = target ? rows.findIndex(r => r.kind === "entry" && r.entry.id === id) : -1;
        list.currentIndex = at >= 0 ? at : rows.findIndex(r => r.kind === "entry");
        if (at >= 0)
            list.positionViewAtIndex(at, ListView.Contain);
        else
            list.positionViewAtBeginning();
        forceActiveFocus();
    }

    function fold(app: string) {
        const f = Object.assign({}, folded);
        f[app] = !f[app];
        folded = f;
    }

    function clearApp(app: string) {
        for (const e of Notifications.list.filter(e => (e.appName || "Other") === app))
            Notifications.remove(e, true);
    }

    function activate(row: var) {
        if (!row)
            return;
        if (row.kind === "header")
            fold(row.app);
        else if (row.entry.hasDefault)
            Notifications.invokeAction(row.entry.id, "default");
    }

    // the icon of a notification: a picture, the app's icon, else none (a bell is drawn)
    function iconOf(e: var): string {
        const i = e?.appIcon ?? "";
        if (i.startsWith("material:"))
            return "";
        if (i.startsWith("/"))
            return "file://" + i;
        if (i.startsWith("file:") || i.startsWith("data:") || i.startsWith("image:"))
            return i;
        return Quickshell.iconPath(i || (e?.appName ?? "").toLowerCase(), true);
    }

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab)
            list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1);
        else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab)
            list.currentIndex = Math.max(list.currentIndex - 1, 0);
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
            activate(current);
        else if (e.key === Qt.Key_Delete && current) {
            const app = current.kind === "header" ? current.app : (current.entry.appName || "Other");
            if (e.modifiers & Qt.ShiftModifier || current.kind === "header")
                clearApp(app);
            else
                Notifications.remove(current.entry, true);
        } else
            return;
        e.accepted = true;
    }

    HoverSelect {
        id: hover
    }

    // header ------------------------------------------------------------------
    Item {
        id: header
        width: parent.width
        height: 40

        K.StyledText {
            id: title
            anchors.left: parent.left
            anchors.leftMargin: Tokens.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 17
            font.weight: Font.Bold
            color: root.c.strong
        }
        K.StyledText {
            anchors.left: title.right
            anchors.leftMargin: 8
            anchors.baseline: title.baseline
            text: Notifications.list.length > 0 ? String(Notifications.list.length) : ""
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 13
            color: root.c.weak
        }

        ActionGroup {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 168
            look: K.Kit.appLook
            actions: [
                {
                    icon: Notifications.silent ? "notifications_off" : "notifications",
                    iconOnly: true,
                    primary: Notifications.silent,
                    run: () => Notifications.silent = !Notifications.silent
                },
                {
                    text: "Clear all",
                    icon: "clear_all",
                    enabled: Notifications.list.length > 0,
                    run: () => Notifications.discardAllNotifications()
                }
            ]
        }
    }

    // list --------------------------------------------------------------------
    ListView {
        id: list
        anchors.top: header.bottom
        anchors.topMargin: Tokens.spacing.s
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        model: root.rows
        spacing: 2
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
            focusShape: root.current?.kind === "entry" ? root.focusShape : null
            rowHeight: root.current?.kind === "header" ? root.headerHeight : root.rowHeight
            iconX: Tokens.spacing.s + 16
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool isHeader: modelData.kind === "header"
            readonly property var entry: modelData.entry ?? null
            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool open: isCurrent && !isHeader
            readonly property var buttons: {
                if (!entry)
                    return [];
                const out = entry.actions.slice(0, 3).map(a => ({
                            text: a.text,
                            run: () => Notifications.invokeAction(entry.id, a.identifier)
                        }));
                out.push({
                    text: "Dismiss",
                    icon: "close",
                    run: () => Notifications.remove(entry, true)
                });
                return out;
            }

            width: list.width
            // grown: the body from the row's middle, then the buttons
            height: isHeader ? root.headerHeight : open ? Math.max(root.rowHeight, Math.round(root.rowHeight / 2) + 1 + fullBody.height + 8 + 32 + 10) : root.rowHeight
            clip: true
            Behavior on height {
                K.Anim {
                    type: K.Anim.FastSpatial
                }
            }

            // a group's header: the app, its count, fold and clear
            Item {
                anchors.fill: parent
                visible: row.isHeader

                K.MaterialIcon {
                    id: chevron
                    x: Tokens.spacing.s + 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.folded[row.modelData.app] ? "chevron_right" : "expand_more"
                    size: 20
                    color: root.c.weak
                }
                K.StyledText {
                    anchors.left: chevron.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: (row.modelData.app ?? "") + "  ·  " + (row.modelData.count ?? 0)
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 12
                    font.weight: 600
                    color: root.c.weak
                }
            }

            // a notification
            Item {
                anchors.fill: parent
                visible: !row.isHeader

                IconImage {
                    id: icon
                    // (a url: `source !== ""` is always true)
                    readonly property string path: row.entry ? root.iconOf(row.entry) : ""
                    x: Tokens.spacing.s
                    y: Math.round((root.rowHeight - height) / 2)
                    implicitSize: 32
                    visible: path !== ""
                    source: path
                    asynchronous: true
                }
                K.MaterialIcon {
                    anchors.centerIn: icon
                    visible: !icon.visible
                    text: "notifications"
                    size: 22
                    fill: row.isCurrent ? 1 : 0
                    color: row.isCurrent && root.c.shapes ? root.c.overAccent : root.c.accent
                }

                K.StyledText {
                    id: summary
                    anchors.left: icon.right
                    anchors.leftMargin: Tokens.spacing.m
                    anchors.right: age.left
                    anchors.rightMargin: 8
                    y: Math.round(root.rowHeight / 2) - height
                    text: row.entry?.summary || row.entry?.appName || ""
                    elide: Text.ElideRight
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 14
                    font.weight: row.isCurrent && root.c.kind === "tone" ? Font.Bold : Font.Medium
                    color: row.isCurrent || root.c.shapes ? root.c.strong : root.c.weak
                }
                K.StyledText {
                    anchors.left: summary.left
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.spacing.m
                    y: Math.round(root.rowHeight / 2) + 1
                    visible: !row.open
                    text: (row.entry?.body ?? "").replace(/\s*\n+\s*/g, " ")
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 12
                    color: root.c.weak
                }
                K.StyledText {
                    id: age
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.spacing.m
                    anchors.baseline: summary.baseline
                    text: row.entry ? (root.minute, Notifications.age(row.entry.time)) : ""
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 11
                    color: root.c.weak
                }

                // grown: the whole body and the buttons
                K.StyledText {
                    id: fullBody
                    anchors.left: summary.left
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.spacing.m
                    y: Math.round(root.rowHeight / 2) + 1
                    opacity: row.open ? 1 : 0
                    text: row.entry?.body ?? ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 8
                    elide: Text.ElideRight
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 12
                    color: root.c.weak
                    Behavior on opacity {
                        K.Anim {
                            type: K.Anim.FastEffects
                        }
                    }
                }
            }

            K.StateLayer {
                id: mouse
                radius: K.Kit.rounding.large
                color: root.c.strong
                stateOpacity: containsMouse && !row.isCurrent ? 0.08 : 0
                onPositionChanged: m => hover.moved(mouse, m, () => list.currentIndex = row.index)
                onClicked: {
                    list.currentIndex = row.index;
                    root.activate(row.modelData);
                }
            }

            ActionGroup {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.spacing.s + 32 + Tokens.spacing.m
                anchors.right: parent.right
                anchors.rightMargin: Tokens.spacing.m
                y: fullBody.y + fullBody.height + 8
                visible: opacity > 0
                opacity: row.open ? 1 : 0
                look: K.Kit.appLook
                idleFill: root.c.shapes ? K.Kit.expressive.high : root.c.off
                actions: row.open ? row.buttons : []
                Behavior on opacity {
                    K.Anim {
                        type: K.Anim.FastEffects
                    }
                }
            }
        }

        // nothing
        Column {
            anchors.centerIn: parent
            visible: list.count === 0
            spacing: 6

            K.MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "notifications_none"
                size: 32
                color: root.c.weak
            }
            K.StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No notifications"
                font.family: K.Kit.family
                font.variableAxes: K.Kit.axes
                font.pixelSize: 13
                color: root.c.weak
            }
        }
    }
}
