import QtQuick
import qs.core
import qs.services
import qs.components
import qs.theme
import "actions.js" as ToolActions

// Screen tools. Every action runs after the island closed,
// so the island never shows up in captures.
FocusScope {
    id: root

    implicitWidth: actions.implicitWidth
    implicitHeight: actions.implicitHeight

    function opened() {
        actions.currentIndex = actions.firstValid();
        actions.reshuffle();
        actions.forceActiveFocus();
    }

    // the actions (actions.js, shared with the Tools Qwidgets) with their icons
    function withIcon(a: var): var {
        return Object.assign({}, a, {
            icon: Icons[a.icon] ?? a.icon
        });
    }
    readonly property var recordActions: ScreenTools.recording ? [Object.assign(withIcon(ToolActions.STOP), {
            text: ScreenTools.elapsedText,
            live: true
        })] : ToolActions.RECORDS.map(withIcon)

    ActionRow {
        id: actions
        focus: true
        // hints = caption under the buttons (Store.hints.tools)
        showCaption: Store.hints.tools

        actions: [...ToolActions.SHOTS.map(root.withIcon), {
                separator: true
            }, ...root.recordActions, {
                separator: true
            }, ...ToolActions.OTHERS.map(root.withIcon)]

        onTriggered: action => Actions.runTool(action.id)
    }
}
