import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.services
import qs.components
import qs.theme
import "actions.js" as SessionActions

// Power menu: lock, suspend, hibernate, logout, reboot, power off.
FocusScope {
    id: root

    implicitWidth: actions.implicitWidth
    implicitHeight: actions.implicitHeight

    function opened() {
        actions.currentIndex = actions.firstValid();
        actions.reshuffle();
        actions.forceActiveFocus();
    }

    ActionRow {
        id: actions
        focus: true
        // hints = caption under the buttons (Store.hints.session)
        showCaption: Store.hints.session

        // actions.js (shared with the Session Qwidgets); lock needs hyprlock
        actions: SessionActions.ACTIONS.map(a => Object.assign({}, a, {
                icon: Icons[a.icon] ?? a.icon,
                label: a.id === "lock" && !Session.hasLocker ? "Lock (install hyprlock)" : a.label,
                enabled: a.id !== "lock" || Session.hasLocker
            }))

        onTriggered: action => Actions.runSession(action.id)
    }
}
