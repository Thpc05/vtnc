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

// App launcher: search field + results list (2026-10-17, apps' look K.Kit.appStyle). Rows show the
// icon, the name and its description; the current one is marked in the look (Shapes the container and
// an accent M3 shape behind its icon, the workspaces Iwidget's focus shape: a random other on every
// move, a new one each open; Two tones the container tinted with the primary; Tone a bar at its left)
// and, when the app has its
// own desktop actions (New Window, New Private Window…; user), it grows to show up to three of them as
// one connected group under its name.
// Type to filter, ↑/↓ (or Tab) to move, Enter to launch, Ctrl+1…3 the current app's actions. Fixed
// size so the island doesn't jump while typing.
FocusScope {
    id: root

    readonly property int itemHeight: 48
    readonly property int visibleItems: 6
    // the current row's actions: the group and the gap above it
    readonly property int actionsHeight: 32 + 8
    readonly property var results: Apps.query(input.text)
    readonly property var current: results[list.currentIndex] ?? null
    // the current app's first three desktop actions
    readonly property var currentActions: {
        const e = current;
        if (!e)
            return [];
        return (e.actions ?? []).slice(0, 3).map(a => ({
                    text: a.name,
                    icon: root.actionIcon(a.name),
                    run: () => root.runAction(a)
                }));
    }

    // a Material symbol for a desktop action, from its name
    function actionIcon(name: string): string {
        const n = (name ?? "").toLowerCase();
        if (/private|incognito/.test(n))
            return "visibility_off";
        if (/window/.test(n))
            return "open_in_new";
        if (/tab/.test(n))
            return "tab";
        if (/new|create|compose/.test(n))
            return "add";
        if (/profile|account|manager/.test(n))
            return "manage_accounts";
        if (/settings|preferences|config/.test(n))
            return "settings";
        return "arrow_outward";
    }

    function runAction(action: var) {
        const entry = current;
        if (!entry)
            return;
        Runtime.closeApp();
        Apps.launchAction(entry, action);
    }

    // Shapes: the current icon's M3 shape
    readonly property FocusShape focusShape: FocusShape {}
    Connections {
        target: list
        function onCurrentIndexChanged() {
            root.focusShape.next();
        }
    }

    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }

    implicitWidth: 480
    // room for the current row's actions too: the last row never hides behind them
    implicitHeight: input.height + Tokens.spacing.s + itemHeight * visibleItems + actionsHeight

    HoverSelect {
        id: hover
    }

    // args.query: initial search text (IPC `launcher search <text>`)
    function opened(args) {
        hover.reset();
        focusShape.reshuffle();
        input.text = args?.query ?? "";
        list.currentIndex = 0;
        list.positionViewAtBeginning();
        input.forceActiveFocus();
    }

    function launch(index: int) {
        const entry = results[index];
        if (!entry)
            return;
        Runtime.closeApp();
        Apps.launch(entry);
    }

    // search field
    K.SearchBar {
        id: input
        width: parent.width
        focus: true
        placeholderText: "Search apps…"
        font: Qt.font({
            family: K.Kit.family,
            pixelSize: Tokens.font.large,
            variableAxes: K.Kit.axes
        })

        onTextChanged: list.currentIndex = 0

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier)) || (e.key === Qt.Key_J && e.modifiers & Qt.ControlModifier))
                list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1);
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || (e.key === Qt.Key_K && e.modifiers & Qt.ControlModifier))
                list.currentIndex = Math.max(list.currentIndex - 1, 0);
            else if (e.key === Qt.Key_PageDown)
                list.currentIndex = Math.min(list.currentIndex + root.visibleItems, list.count - 1);
            else if (e.key === Qt.Key_PageUp)
                list.currentIndex = Math.max(list.currentIndex - root.visibleItems, 0);
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                root.launch(list.currentIndex);
            else if (e.modifiers & Qt.ControlModifier && e.key >= Qt.Key_1 && e.key <= Qt.Key_3 && root.currentActions[e.key - Qt.Key_1])
                root.currentActions[e.key - Qt.Key_1].run();
            else
                return;
            e.accepted = true;
        }
    }


    ListView {
        id: list
        anchors.top: input.bottom
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

        // the current row in the look (apps/common/RowHighlight.qml)
        highlight: RowHighlight {
            c: root.c
            focusShape: root.focusShape
            rowHeight: root.itemHeight
            iconX: Tokens.spacing.s + 16
        }

        delegate: Item {
            id: item
            required property DesktopEntry modelData
            required property int index
            readonly property bool isCurrent: ListView.isCurrentItem
            // the current one grows when the app has its own actions
            readonly property bool open: isCurrent && root.currentActions.length > 0

            width: list.width
            height: root.itemHeight + (open ? root.actionsHeight : 0)
            clip: true
            Behavior on height {
                K.Anim {
                    type: K.Anim.FastSpatial
                }
            }

            IconImage {
                id: appIcon
                anchors.left: parent.left
                anchors.leftMargin: Tokens.spacing.s
                y: Math.round((root.itemHeight - height) / 2)
                implicitSize: 32
                source: Quickshell.iconPath(item.modelData.icon, true) || Quickshell.iconPath("application-x-executable", true) || Quickshell.iconPath("application-default-icon", true)
                asynchronous: true
            }

            Column {
                anchors.left: appIcon.right
                anchors.leftMargin: Tokens.spacing.m
                anchors.right: parent.right
                anchors.rightMargin: Tokens.spacing.m
                y: Math.round((root.itemHeight - height) / 2)

                K.StyledText {
                    width: parent.width
                    text: item.modelData.name
                    elide: Text.ElideRight
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 14
                    font.weight: item.isCurrent && root.c.kind === "tone" ? Font.Bold : Font.Medium
                    color: item.isCurrent || root.c.shapes ? root.c.strong : root.c.weak
                }

                K.StyledText {
                    width: parent.width
                    visible: text !== ""
                    text: item.modelData.comment || item.modelData.genericName
                    elide: Text.ElideRight
                    font.family: K.Kit.family
                    font.variableAxes: K.Kit.axes
                    font.pixelSize: 12
                    color: root.c.weak
                }
            }

            K.StateLayer {
                id: itemMouse
                radius: K.Kit.rounding.large
                color: root.c.strong
                // the current row is already marked: only the ripple there
                stateOpacity: containsMouse && !item.isCurrent ? 0.08 : 0
                onPositionChanged: m => hover.moved(itemMouse, m, () => list.currentIndex = item.index)
                onClicked: root.launch(item.index)
            }

            // the app's own actions, over the row's click
            ActionGroup {
                anchors.left: appIcon.left
                anchors.right: parent.right
                anchors.rightMargin: Tokens.spacing.s
                y: root.itemHeight
                visible: opacity > 0
                opacity: item.open ? 1 : 0
                look: K.Kit.appLook
                // Shapes: the row is the container, one step up for the buttons
                idleFill: root.c.shapes ? K.Kit.expressive.high : root.c.off
                actions: item.isCurrent ? root.currentActions : []
                Behavior on opacity {
                    K.Anim {
                        type: K.Anim.FastEffects
                    }
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "No apps found"
            color: Colors.outline
        }
    }
}
