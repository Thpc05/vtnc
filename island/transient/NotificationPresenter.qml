import QtQuick
import qs.core
import qs.services

// Decides when the notification transient shows (one for the whole shell, in shell.qml):
//  - popups (Notifications.popupList) go to the focused monitor once its island is free:
//    no other transient (an OSD) and, replacing the island, no app (apps follow the focused monitor);
//    growing (island.notifications.presentation "grow") they hang under an open app too
//  - then, per the island's mode there (island.notifications.compact / expanded):
//    "transient" → the island becomes the card; "widget" → only the bell iwidget reacts
//    (Runtime.ringBell: it shakes, appearing for a moment if hidden in that mode) and the popups
//    are dropped at once (they stay in the list). With the bell off (not in the island) there's
//    nothing to ring, so it's always the transient
//  - while they wait, their timers are paused so nothing expires unseen; showing resumes them
//  - the transient ends when popupList is empty (timeouts, dismiss, actions)
//  - interrupted (an app opened, an OSD replaced it): they wait again and come back when free
// Do not disturb (Notifications.silent) creates no popups at all.
Item {
    id: root

    function evaluate() {
        Qt.callLater(root.apply);
    }

    function apply() {
        const transients = Runtime.transients;
        const showing = Object.keys(transients).find(s => transients[s].kind === "notification") ?? "";
        const pending = Notifications.popupList.length > 0;

        if (showing !== "") {
            if (!pending)
                Runtime.endTransient(showing, "notification");
            return;
        }
        if (!pending)
            return;

        const screen = Hypr.focusedScreen;
        const grows = Store.island.notifications?.presentation === "grow";
        const free = screen !== "" && (Runtime.activeApp === "" || grows) && Runtime.transientOn(screen) === null;
        if (!free) {
            Notifications.pauseAllTimers();
            return;
        }
        const modes = Store.island.notifications;
        const mode = Runtime.isIslandExpanded(screen) ? modes?.expanded : modes?.compact;
        const bell = (Store.island.widgets ?? []).some(w => w.id === "notifications" && w.section !== "off");
        if (mode === "widget" && bell) {
            Notifications.hideAllPopups();
            Runtime.ringBell(screen);
            return;
        }
        Notifications.resumeAllTimers();
        Runtime.showTransient(screen, "notification", {}, 0);
    }

    Connections {
        target: Notifications
        function onPopupListChanged() {
            root.evaluate();
        }
    }
    Connections {
        target: Runtime
        function onTransientsChanged() {
            root.evaluate();
        }
        function onActiveAppChanged() {
            root.evaluate();
        }
        function onPinnedExpandedChanged() {
            root.evaluate();
        }
    }
    Connections {
        target: Hypr
        function onFocusedScreenChanged() {
            root.evaluate();
        }
    }
}
